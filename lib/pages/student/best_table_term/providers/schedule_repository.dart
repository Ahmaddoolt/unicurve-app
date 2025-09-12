import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider((ref) => Supabase.instance.client);

final scheduleDataCacheProvider = Provider((ref) => {});

final studentMajorIdProvider = FutureProvider.autoDispose<int>((ref) {
  ref.keepAlive();
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) throw Exception("User not authenticated.");

  return client
      .from('students')
      .select('major_id')
      .eq('user_id', userId)
      .single()
      .then((response) {
        if (response['major_id'] == null) {
          throw Exception(
            'Student major not found. Please contact administration.',
          );
        }
        return response['major_id'];
      });
});

final passedSubjectIdsProvider = FutureProvider.autoDispose<Set<int>>((
  ref,
) async {
  ref.keepAlive();
  ref.watch(scheduleDataCacheProvider);

  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return {};

  final response = await client
      .from('student_taken_subjects')
      .select('subject_id')
      .eq('student_user_id', userId)
      .eq('status', 'passed');

  return (response as List).map<int>((e) => e['subject_id']).toSet();
});

final prerequisiteMapProvider = FutureProvider.autoDispose<Map<int, Set<int>>>((
  ref,
) async {
  ref.keepAlive();
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('subject_relationships')
      .select('source_subject_id, target_subject_id')
      .eq('relationship_type', 'PREREQUISITE');

  final Map<int, Set<int>> prereqMap = {};
  for (var rel in response) {
    final target = rel['target_subject_id'] as int;
    final source = rel['source_subject_id'] as int;
    prereqMap.putIfAbsent(target, () => <int>{}).add(source);
  }
  return prereqMap;
});

final unlockCountMapProvider = FutureProvider.autoDispose<Map<int, int>>((
  ref,
) async {
  ref.keepAlive();
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('subject_relationships')
      .select('source_subject_id')
      .eq('relationship_type', 'PREREQUISITE');

  final Map<int, int> unlockMap = {};
  for (var rel in response) {
    final source = rel['source_subject_id'] as int;
    unlockMap[source] = (unlockMap[source] ?? 0) + 1;
  }
  return unlockMap;
});

final majorRequirementsProvider =
    FutureProvider.autoDispose<Map<int, Map<String, dynamic>>>((ref) async {
      ref.keepAlive();
      final client = ref.watch(supabaseClientProvider);
      final majorId = await ref.watch(studentMajorIdProvider.future);

      final response = await client
          .from('major_requirements')
          .select('id, requirement_name, required_hours')
          .eq('major_id', majorId);

      final Map<int, Map<String, dynamic>> requirementsMap = {};
      for (var req in response) {
        requirementsMap[req['id']] = {
          'name': req['requirement_name'],
          'hours': req['required_hours'],
        };
      }
      return requirementsMap;
    });

final hoursTakenPerTypeProvider = FutureProvider.autoDispose<Map<int, int>>((
  ref,
) async {
  ref.keepAlive();
  ref.watch(scheduleDataCacheProvider);

  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return {};

  final response = await client
      .from('student_taken_subjects')
      .select('subjects(type, hours)')
      .eq('student_user_id', userId)
      .eq('status', 'passed');

  final Map<int, int> hoursTakenMap = {};
  for (var record in response) {
    final subject = record['subjects'];
    if (subject != null) {
      final typeId = subject['type'] as int?;
      final hours = subject['hours'] as int?;
      if (typeId != null && hours != null) {
        hoursTakenMap[typeId] = (hoursTakenMap[typeId] ?? 0) + hours;
      }
    }
  }
  return hoursTakenMap;
});

class ScheduleRepository {
  final SupabaseClient _client;
  ScheduleRepository(this._client);

  Future<List<Map<String, dynamic>>> getOpenSubjectsWithGroups(
    int majorId,
  ) async {
    return await _client
        .from('subjects')
        .select('*, subject_groups(*, subject_schedules(*))')
        .eq('major_id', majorId)
        .eq('is_open', true);
  }
}

final scheduleRepositoryProvider = Provider((ref) {
  return ScheduleRepository(ref.watch(supabaseClientProvider));
});
