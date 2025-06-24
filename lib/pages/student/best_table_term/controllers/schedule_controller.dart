import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/pages/student/best_table_term/providers/schedule_generator_provider.dart';
import 'package:unicurve/pages/student/best_table_term/providers/schedule_repository.dart';
import 'package:unicurve/pages/student/best_table_term/views/best_schedule_page.dart';

final togglingSubjectIdProvider = StateProvider<int?>((ref) => null);

class ScheduleController {
  final WidgetRef ref;

  ScheduleController(this.ref);

  Future<void> refreshSchedules(int selectedRank) async {
    ref.read(isRefreshingProvider.notifier).state = true;
    ref.invalidate(scheduleDataCacheProvider);
    ref.invalidate(bannedSubjectsInitializerProvider);
    ref.invalidate(prioritizedSubjectsProvider);
    for (var i = 0; i < 3; i++) {
      ref.invalidate(scheduleGeneratorProvider(i));
    }
    await ref.read(scheduleGeneratorProvider(selectedRank).future);
    ref.read(isRefreshingProvider.notifier).state = false;
  }

  Future<void> setSubjectBannedStatus(
    int subjectId, {
    required bool shouldBeBanned,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      // print('Error: User not authenticated');
      return;
    }

    ref.read(togglingSubjectIdProvider.notifier).state = subjectId;
    try {
      ref.read(bannedSubjectsProvider.notifier).update((state) {
        final newState = {...state};
        if (shouldBeBanned) {
          newState.add(subjectId);
        } else {
          newState.remove(subjectId);
        }
        // print('Updated bannedSubjectsProvider: $newState');
        return newState;
      });

      if (shouldBeBanned) {
        await client.from('banned_subjects').upsert({
          'user_id': userId,
          'subject_id': subjectId,
        }, onConflict: 'user_id,subject_id');
        // print('Banned subject $subjectId');
      } else {
        await client
            .from('banned_subjects')
            .delete()
            .eq('user_id', userId)
            .eq('subject_id', subjectId);
        // print('Unbanned subject $subjectId');
      }

      ref.invalidate(prioritizedSubjectsProvider);
      // print('Invalidated prioritizedSubjectsProvider');
    } catch (e) {
      // print('Error setting subject banned status: $e');
    } finally {
      ref.read(togglingSubjectIdProvider.notifier).state = null;
    }
  }

  void setScheduleRank(int rank) {
    ref.read(scheduleRankProvider.notifier).state = rank;
  }

  void setScheduleView(ScheduleView view) {
    ref.read(scheduleViewProvider.notifier).state = view;
  }

  void setMaxHours(int hours) {
    ref.read(maxHoursProvider.notifier).state = hours;
  }

  void setMinimizeDays(bool minimize) {
    ref.read(minimizeDaysProvider.notifier).state = minimize;
  }
}
