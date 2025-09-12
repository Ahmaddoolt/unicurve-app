import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/domain/models/schedule_models.dart';
import 'package:unicurve/pages/student/best_table_term/providers/schedule_repository.dart';

final bannedSubjectsProvider = StateProvider<Set<int>>((ref) => {});

final bannedSubjectsInitializerProvider = FutureProvider.autoDispose<void>((
  ref,
) async {
  ref.keepAlive();
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) {
    // print('Error: User not authenticated');
    return;
  }

  try {
    final response = await client
        .from('banned_subjects')
        .select('subject_id')
        .eq('user_id', userId);

    final bannedSubjectIds =
        (response as List).map<int>((e) => e['subject_id']).toSet();

    ref.read(bannedSubjectsProvider.notifier).state = bannedSubjectIds;
    // print('Initialized bannedSubjectsProvider: $bannedSubjectIds');
  } catch (e) {
    // print('Error fetching banned subjects: $e');
    ref.read(bannedSubjectsProvider.notifier).state = {};
  }
});

final maxHoursProvider = StateProvider<int>((ref) => 18);
final minimizeDaysProvider = StateProvider<bool>((ref) => false);

final prioritizedSubjectsProvider = FutureProvider.autoDispose<
  List<AvailableSubject>
>((ref) async {
  ref.keepAlive();

  await ref.watch(bannedSubjectsInitializerProvider.future);

  final bannedSubjectIds = ref.watch(bannedSubjectsProvider);
  // print(
  //   'prioritizedSubjectsProvider rebuilding with bannedSubjectIds: $bannedSubjectIds',
  // );

  final results = await Future.wait([
    ref.watch(passedSubjectIdsProvider.future),
    ref.watch(prerequisiteMapProvider.future),
    ref.watch(unlockCountMapProvider.future),
    ref.watch(studentMajorIdProvider.future),
    ref.watch(majorRequirementsProvider.future),
    ref.watch(hoursTakenPerTypeProvider.future),
  ]);
  final passedIds = results[0] as Set<int>;
  final prereqMap = results[1] as Map<int, Set<int>>;
  final unlockMap = results[2] as Map<int, int>;
  final majorId = results[3] as int;
  final requirementsMap = results[4] as Map<int, Map<String, dynamic>>;
  final hoursTakenMap = results[5] as Map<int, int>;
  final repo = ref.read(scheduleRepositoryProvider);
  final allSubjectsForMajor = await repo.getOpenSubjectsWithGroups(majorId);

  final availableSubjectsRaw = <Map<String, dynamic>>[];
  final bannedSubjectsRaw = <Map<String, dynamic>>[];

  for (var subject in allSubjectsForMajor) {
    final subjectId = subject['id'];
    if (passedIds.contains(subjectId)) continue;
    final prerequisites = prereqMap[subjectId] ?? <int>{};
    if (!passedIds.containsAll(prerequisites)) continue;
    final groups = subject['subject_groups'] as List;
    if (groups.every((g) => (g['subject_schedules'] as List).isEmpty)) continue;
    final typeId = subject['type'] as int?;
    final requiredHours = requirementsMap[typeId]?['hours'] as int?;
    final takenHours = hoursTakenMap[typeId] ?? 0;
    final meetsHourRequirement =
        requiredHours == null || takenHours < requiredHours;

    if (bannedSubjectIds.contains(subjectId)) {
      bannedSubjectsRaw.add(subject);
    } else if (meetsHourRequirement) {
      availableSubjectsRaw.add(subject);
    }
  }

  final availableSubjects =
      [...availableSubjectsRaw, ...bannedSubjectsRaw].map((subject) {
        final dynamicPriority = unlockMap[subject['id']] ?? 0;
        final staticPriority = (subject['priority'] as num?)?.toInt() ?? 0;
        final typeId = subject['type'] as int?;
        final subjectId = subject['id'];
        return AvailableSubject(
          subject: subject,
          groups:
              (subject['subject_groups'] as List? ?? [])
                  .cast<Map<String, dynamic>>()
                  .toList(),
          priority: dynamicPriority + staticPriority,
          requirementName:
              requirementsMap[typeId]?['name'] ?? 'General Elective',
          isBanned: bannedSubjectIds.contains(subjectId),
        );
      }).toList();

  availableSubjects.sort((a, b) => b.priority.compareTo(a.priority));
  return availableSubjects;
});

final scheduleGeneratorProvider = FutureProvider.family.autoDispose<
  ScheduleResult,
  int
>((ref, rank) async {
  final maxHours = ref.watch(maxHoursProvider);
  final shouldMinimizeDays = ref.watch(minimizeDaysProvider);

  final prioritizedSubjects = await ref.watch(
    prioritizedSubjectsProvider.future,
  );

  final activeSubjects = prioritizedSubjects.where((s) => !s.isBanned).toList();

  final priorityMap = {
    for (var s in activeSubjects) s.subject['id'] as int: s.priority,
  };

  int calculateSchedulePriority(ScheduleResult schedule) {
    return schedule.scheduledCourses.fold<int>(
      0,
      (sum, course) => sum + (priorityMap[course.subject['id']] ?? 0),
    );
  }

  Future<ScheduleResult> findBestSchedule(
    List<AvailableSubject> subjects,
  ) async {
    final generator = ScheduleGenerator(maxHours: maxHours);
    final possibleSchedules = await generator.generateSchedules(subjects);

    if (possibleSchedules.isEmpty) {
      return ScheduleResult.empty();
    }

    if (shouldMinimizeDays) {
      final maxHoursAchieved = possibleSchedules
          .map((s) => s.totalHours)
          .reduce(max);
      final highValueSchedules =
          possibleSchedules
              .where((s) => s.totalHours >= maxHoursAchieved - 3)
              .toList();

      if (highValueSchedules.isEmpty) {
        return possibleSchedules.first;
      }

      highValueSchedules.sort((a, b) {
        final dayComparison = a.uniqueDays.compareTo(b.uniqueDays);
        if (dayComparison != 0) return dayComparison;
        final hourComparison = b.totalHours.compareTo(a.totalHours);
        if (hourComparison != 0) return hourComparison;
        return calculateSchedulePriority(
          b,
        ).compareTo(calculateSchedulePriority(a));
      });

      return highValueSchedules.first;
    } else {
      possibleSchedules.sort((a, b) {
        final priorityComparison = calculateSchedulePriority(
          b,
        ).compareTo(calculateSchedulePriority(a));
        if (priorityComparison != 0) return priorityComparison;
        final hourComparison = b.totalHours.compareTo(a.totalHours);
        if (hourComparison != 0) return hourComparison;
        return b.scheduledCourses.length.compareTo(a.scheduledCourses.length);
      });

      return possibleSchedules.first;
    }
  }

  final bestTop1Schedule = await findBestSchedule(activeSubjects);

  if (rank == 0) {
    return bestTop1Schedule;
  }

  if (bestTop1Schedule.scheduledCourses.isEmpty) {
    return ScheduleResult.empty();
  }

  final top1SubjectIds =
      bestTop1Schedule.scheduledCourses
          .map((c) => c.subject['id'] as int)
          .toSet();

  final usedSubjectsSortedByPriority =
      activeSubjects
          .where((s) => top1SubjectIds.contains(s.subject['id']))
          .toList();

  if (usedSubjectsSortedByPriority.length <= rank) {
    return ScheduleResult.empty();
  }

  final subjectsToExclude =
      usedSubjectsSortedByPriority
          .sublist(usedSubjectsSortedByPriority.length - rank)
          .map((s) => s.subject['id'] as int)
          .toSet();

  final subjectsForThisRank =
      activeSubjects
          .where((s) => !subjectsToExclude.contains(s.subject['id']))
          .toList();

  return await findBestSchedule(subjectsForThisRank);
});

class ScheduleGenerator {
  final int maxHours;
  ScheduleGenerator({required this.maxHours});

  Future<List<ScheduleResult>> generateSchedules(
    List<AvailableSubject> availableSubjects,
  ) async {
    final List<ScheduleResult> foundSchedules = [];
    _findScheduleRecursive(
      availableSubjects,
      ScheduleResult.empty(),
      foundSchedules,
    );
    return foundSchedules;
  }

  void _findScheduleRecursive(
    List<AvailableSubject> remainingSubjects,
    ScheduleResult currentSchedule,
    List<ScheduleResult> solutions,
  ) {
    if (solutions.length > 300) {
      return;
    }

    if (remainingSubjects.isEmpty) {
      if (currentSchedule.scheduledCourses.isNotEmpty) {
        solutions.add(currentSchedule);
      }
      return;
    }

    final subjectToAdd = remainingSubjects.first;
    final otherSubjects = remainingSubjects.sublist(1);

    for (final group in subjectToAdd.groups) {
      final allSchedulesInGroup =
          (group['subject_schedules'] as List? ?? [])
              .cast<Map<String, dynamic>>();
      if (allSchedulesInGroup.isEmpty) continue;

      final theoreticalSchedules =
          allSchedulesInGroup
              .where((s) => s['schedule_type'] == 'THEORETICAL')
              .toList();
      final practicalSchedules =
          allSchedulesInGroup
              .where((s) => s['schedule_type'] == 'PRACTICAL')
              .toList();

      final List<List<Map<String, dynamic>>> scheduleOptions = [];
      if (practicalSchedules.isEmpty) {
        if (theoreticalSchedules.isNotEmpty) {
          scheduleOptions.add(theoreticalSchedules);
        }
      } else {
        for (final practicalSchedule in practicalSchedules) {
          scheduleOptions.add([...theoreticalSchedules, practicalSchedule]);
        }
      }

      for (final scheduleOption in scheduleOptions) {
        if (scheduleOption.isEmpty) continue;
        final newTimeSlots =
            scheduleOption
                .map(
                  (s) => TimeSlot(
                    s['day_of_week'],
                    s['start_time'],
                    s['end_time'],
                  ),
                )
                .toList();
        final hasConflict = newTimeSlots.any(
          (newSlot) => currentSchedule.timeSlots.any(
            (existingSlot) => newSlot.conflictsWith(existingSlot),
          ),
        );
        final newTotalHours =
            currentSchedule.totalHours +
            ((subjectToAdd.subject['hours'] as num?)?.toInt() ?? 0);

        if (!hasConflict && newTotalHours <= maxHours) {
          final newScheduledCourse = ScheduledCourse(
            subject: subjectToAdd.subject,
            group: group,
            schedules: scheduleOption,
          );
          final newSchedule = ScheduleResult(
            scheduledCourses: [
              ...currentSchedule.scheduledCourses,
              newScheduledCourse,
            ],
            totalHours: newTotalHours,
            timeSlots: [...currentSchedule.timeSlots, ...newTimeSlots],
          );
          _findScheduleRecursive(otherSubjects, newSchedule, solutions);
        }
      }
    }
    _findScheduleRecursive(otherSubjects, currentSchedule, solutions);
  }
}
