import 'dart:async'; // Import 'dart:async' for the Completer
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/pages/student/providers/academic_profile_provider.dart';

// Represents a final, scheduled course with a specific group
class ScheduledCourse {
  final Map<String, dynamic> subject;
  final Map<String, dynamic> group;
  final List<Map<String, dynamic>> schedules;

  ScheduledCourse({
    required this.subject,
    required this.group,
    required this.schedules,
  });
}

// The result of the generation
class ScheduleResult {
  final List<ScheduledCourse> scheduledCourses;
  final int totalHours;

  ScheduleResult({required this.scheduledCourses, required this.totalHours});
}

// The provider that the UI will interact with
final scheduleGeneratorProvider = FutureProvider.autoDispose<ScheduleResult>((ref) {
  final academicProfileAsync = ref.watch(academicProfileProvider);

  return academicProfileAsync.when(
    data: (profile) {
      final generator = ScheduleGenerator(ref, profile);
      return generator.generate();
    },
    error: (error, stackTrace) {
      throw Exception("Dependency Error: Could not get academic profile. $error");
    },
    loading: () {
      return Completer<ScheduleResult>().future;
    },
  );
});


class ScheduleGenerator {
  final Ref ref;
  final AcademicProfile academicProfile;
  final _supabase = Supabase.instance.client;
  
  ScheduleGenerator(this.ref, this.academicProfile);

  Future<ScheduleResult> generate() async {
    // --- FIX IS HERE: ADD A GUARD CLAUSE FOR SAFETY ---
    if (academicProfile.studentData == null) {
      throw Exception('Student profile data not found. Cannot generate schedule.');
    }
    final majorId = academicProfile.studentData!['major_id'];
    if (majorId == null) {
      throw Exception('Student major ID not found in profile. Cannot generate schedule.');
    }
    // --- END OF FIX ---

    final maxHours = (academicProfile.cumulativeGpa >= 3.0) ? 21 : 18;
    
    // Pass the safe majorId to the helper method
    final eligibleSubjects = await _getEligibleSubjects(majorId);

    final result = _findBestScheduleRecursive(
      eligibleSubjects: eligibleSubjects,
      currentSchedule: [],
      occupiedSlots: [],
      currentHours: 0,
      maxHours: maxHours,
    );

    return ScheduleResult(scheduledCourses: result, totalHours: result.fold(0, (sum, course) => sum + (course.subject['hours'] as int)));
  }

  // This is the core backtracking logic
  List<ScheduledCourse> _findBestScheduleRecursive({
    required List<Map<String, dynamic>> eligibleSubjects,
    required List<ScheduledCourse> currentSchedule,
    required List<Map<String, dynamic>> occupiedSlots,
    required int currentHours,
    required int maxHours,
  }) {
    if (eligibleSubjects.isEmpty) {
      return currentSchedule;
    }

    final subjectToTry = eligibleSubjects.first;
    final remainingSubjects = eligibleSubjects.sublist(1);
    final subjectHours = subjectToTry['hours'] as int;

    if (currentHours + subjectHours <= maxHours) {
      final groups = (subjectToTry['subject_groups'] as List)
          .where((g) => g['is_open'] == true)
          .toList();

      for (var group in groups) {
        final schedulesForGroup = (group['subject_schedules'] as List)
            .cast<Map<String, dynamic>>();

        bool hasConflict = false;
        for (var timeSlot in schedulesForGroup) {
          if (_checkTimeConflict(occupiedSlots, timeSlot)) {
            hasConflict = true;
            break;
          }
        }

        if (!hasConflict) {
          final newCourse = ScheduledCourse(
            subject: subjectToTry,
            group: group,
            schedules: schedulesForGroup,
          );
          
          final result = _findBestScheduleRecursive(
            eligibleSubjects: remainingSubjects,
            currentSchedule: [...currentSchedule, newCourse],
            occupiedSlots: [...occupiedSlots, ...schedulesForGroup],
            currentHours: currentHours + subjectHours,
            maxHours: maxHours,
          );
          return result;
        }
      }
    }

    return _findBestScheduleRecursive(
      eligibleSubjects: remainingSubjects,
      currentSchedule: currentSchedule,
      occupiedSlots: occupiedSlots,
      currentHours: currentHours,
      maxHours: maxHours,
    );
  }

  bool _checkTimeConflict(List<Map<String, dynamic>> occupiedSlots, Map<String, dynamic> newSlot) {
    for (var occupied in occupiedSlots) {
      if (occupied['day_of_week'] == newSlot['day_of_week']) {
        final occupiedStart = TimeOfDay.fromDateTime(DateTime.parse('2024-01-01 ${occupied['start_time']}'));
        final occupiedEnd = TimeOfDay.fromDateTime(DateTime.parse('2024-01-01 ${occupied['end_time']}'));
        final newStart = TimeOfDay.fromDateTime(DateTime.parse('2024-01-01 ${newSlot['start_time']}'));
        final newEnd = TimeOfDay.fromDateTime(DateTime.parse('2024-01-01 ${newSlot['end_time']}'));

        if ((newStart.hour < occupiedEnd.hour || (newStart.hour == occupiedEnd.hour && newStart.minute < occupiedEnd.minute)) &&
            (occupiedStart.hour < newEnd.hour || (occupiedStart.hour == newEnd.hour && occupiedStart.minute < newEnd.minute))) {
          return true; // Conflict!
        }
      }
    }
    return false; // No conflict
  }
  
  // Helper to get all data. Now takes majorId as a parameter.
  Future<List<Map<String, dynamic>>> _getEligibleSubjects(int majorId) async {
    final response = await _supabase
      .from('subjects')
      .select('*, subject_groups(*, subject_schedules(*))')
      .eq('major_id', majorId) // Use the safe majorId
      .eq('is_open', true)
      .order('priority', ascending: false);

    final passedIds = academicProfile.takenSubjects
      .where((s) => s['status'] == 'passed')
      .map((s) => s['subject']['id'])
      .toSet();

    final eligible = response.where((s) => !passedIds.contains(s['id'])).toList();

    // TODO: Add prerequisite check logic here
    return eligible;
  }
}