import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/domain/models/subject.dart';

final supabase = Supabase.instance.client;

class SubjectsRepository {
  Future<List<Subject>> getSubjectsByMajor(int majorId) async {
    final response = await supabase.rpc(
      'get_subjects_with_group_count',
      params: {'major_id_param': majorId},
    );
    return (response as List).map((e) => Subject.fromMap(e)).toList();
  }

  Future<List<SubjectGroup>> getGroupsForSubject(int subjectId) async {
    final response = await supabase
        .from('subject_groups')
        .select('*, subject_schedules(*)')
        .eq('subject_id', subjectId)
        .order('group_code');
    return (response as List).map((e) => SubjectGroup.fromMap(e)).toList();
  }

  Future<String?> checkGroupConflict({
    required int subjectId,
    required String groupCode,
    required String scheduleType,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    int? editingScheduleId,
  }) async {
    final allGroupsForSubject = await getGroupsForSubject(subjectId);
    final newStart = startTime.substring(0, 5);
    final newEnd = endTime.substring(0, 5);

    if (scheduleType == 'THEORETICAL') {
      final existingTheoreticalGroup = allGroupsForSubject.where((g) {
        if (editingScheduleId != null) {
          final isSameGroup = g.schedules.any((s) => s.id == editingScheduleId);
          if (isSameGroup) return false;
        }
        return g.groupCode.toLowerCase() == groupCode.toLowerCase();
      });

      if (existingTheoreticalGroup.isNotEmpty) {
        return 'A theoretical group with code "$groupCode" already exists.';
      }
    }

    for (final existingGroup in allGroupsForSubject) {
      for (final existingSchedule in existingGroup.schedules) {
        if (editingScheduleId != null &&
            existingSchedule.id == editingScheduleId) {
          continue;
        }
        if (existingSchedule.dayOfWeek == dayOfWeek) {
          final existingStart = existingSchedule.startTime;
          final existingEnd = existingSchedule.endTime;
          if (newStart.compareTo(existingEnd) < 0 &&
              newEnd.compareTo(existingStart) > 0) {
            return 'Time conflict with Group ${existingGroup.groupCode} (${existingSchedule.dayOfWeek} $existingStart-$existingEnd).';
          }
        }
      }
    }

    return null;
  }

  Future<void> addGroupWithSchedule({
    required int subjectId,
    required String groupCode,
    required String scheduleType,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final existingGroup =
        await supabase
            .from('subject_groups')
            .select('id')
            .eq('subject_id', subjectId)
            .eq('group_code', groupCode)
            .maybeSingle();

    int groupId;
    if (existingGroup != null) {
      groupId = existingGroup['id'];
    } else {
      final newGroupResponse =
          await supabase
              .from('subject_groups')
              .insert({'subject_id': subjectId, 'group_code': groupCode})
              .select('id')
              .single();
      groupId = newGroupResponse['id'];
    }

    await supabase.from('subject_schedules').insert({
      'group_id': groupId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'schedule_type': scheduleType,
    });
  }

  Future<void> updateSchedule(
    int scheduleId, {
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    await supabase
        .from('subject_schedules')
        .update({
          'day_of_week': dayOfWeek,
          'start_time': startTime,
          'end_time': endTime,
        })
        .eq('id', scheduleId);
  }

  Future<void> deleteSchedule(int scheduleId) async {
    await supabase.from('subject_schedules').delete().eq('id', scheduleId);
  }

  Future<void> updateSubjectStatus(int subjectId, bool isOpen) async {
    await supabase
        .from('subjects')
        .update({'is_open': isOpen})
        .eq('id', subjectId);
  }

  Future<void> deleteGroup(int groupId) async {
    await supabase.from('subject_schedules').delete().eq('group_id', groupId);
    await supabase.from('subject_groups').delete().eq('id', groupId);
  }
}

final subjectsRepositoryProvider = Provider((ref) => SubjectsRepository());
final subjectsProvider = FutureProvider.family<List<Subject>, int>((
  ref,
  majorId,
) {
  return ref.watch(subjectsRepositoryProvider).getSubjectsByMajor(majorId);
});
final subjectGroupsProvider = FutureProvider.family<List<SubjectGroup>, int>((
  ref,
  subjectId,
) {
  return ref.watch(subjectsRepositoryProvider).getGroupsForSubject(subjectId);
});
