// lib/pages/student/best_table_term/views/best_schedule_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/glass_loading_overlay.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/schedule_models.dart';
import 'package:unicurve/pages/student/best_table_term/controllers/schedule_controller.dart';
import 'package:unicurve/pages/student/best_table_term/providers/schedule_generator_provider.dart';
import 'package:unicurve/pages/student/best_table_term/views/schedule_agenda_view.dart';
import 'package:unicurve/pages/student/best_table_term/views/schedule_control_view.dart';
import 'package:unicurve/pages/student/best_table_term/views/schedule_dots_view.dart';
import 'package:unicurve/pages/student/best_table_term/views/schedule_list_view.dart';
import 'package:unicurve/pages/student/best_table_term/views/schedule_table_view.dart';

enum ScheduleView { list, table, calendar, dots }

final scheduleViewProvider =
    StateProvider<ScheduleView>((ref) => ScheduleView.dots);
final scheduleRankProvider = StateProvider<int>((ref) => 0);
final isRefreshingProvider = StateProvider<bool>((ref) => false);

// --- NEW: State provider to control the visibility of the control panel ---
final isControlPanelExpandedProvider = StateProvider<bool>((ref) => true);

class BestSchedulePage extends ConsumerStatefulWidget {
  const BestSchedulePage({super.key});

  @override
  ConsumerState<BestSchedulePage> createState() => _BestSchedulePageState();
}

class _BestSchedulePageState extends ConsumerState<BestSchedulePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final controller = ScheduleController(ref);
        _showPriorityListDialog(context, ref, controller);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ScheduleController(ref);
    final selectedRank = ref.watch(scheduleRankProvider);
    final scheduleAsync = ref.watch(scheduleGeneratorProvider(selectedRank));
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final scaleConfig = context.scaleConfig;

    // --- NEW: Watch the state for the control panel's visibility ---
    final isControlPanelExpanded = ref.watch(isControlPanelExpandedProvider);

    final appBar = CustomAppBar(
      useGradient: !isDarkMode,
      title: 'optimal_schedule_title'.tr,
      actions: [
        // --- NEW: Add an icon button to toggle the control panel ---
        IconButton(
          tooltip: isControlPanelExpanded ? 'Hide Options' : 'Show Options',
          icon: Icon(
            isControlPanelExpanded
                ? Icons.expand_less_rounded
                : Icons.expand_more_rounded,
          ),
          onPressed: () {
            ref.read(isControlPanelExpandedProvider.notifier).state =
                !isControlPanelExpanded;
          },
        ),
        IconButton(
          tooltip: 'view_subjects_list_tooltip'.tr,
          icon: const Icon(Icons.format_list_numbered),
          onPressed: () => _showPriorityListDialog(context, ref, controller),
        ),
        // Consumer(
        //   builder: (context, ref, child) {
        //     final isRefreshing = ref.watch(isRefreshingProvider);
        //     return isRefreshing
        //         ? Padding(
        //             padding: const EdgeInsets.only(right: 14.0),
        //             child: SizedBox(
        //               width: 20,
        //               height: 20,
        //               child: CircularProgressIndicator(
        //                 strokeWidth: 2.5,
        //                 color: isDarkMode ? Colors.white : AppColors.primary,
        //               ),
        //             ),
        //           )
        //         : IconButton(
        //             tooltip: 'refresh_data_tooltip'.tr,
        //             icon: const Icon(Icons.sync),
        //             onPressed: () => controller.refreshSchedules(selectedRank),
        //           );
        //   },
        // ),
      ],
    );

    final bodyContent = GlassLoadingOverlay(
      isLoading: scheduleAsync.isLoading && !scheduleAsync.hasValue,
      child: Column(
        children: [
          // --- NEW: Wrap ScheduleControlView in an AnimatedSize widget ---
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isControlPanelExpanded
                ? ScheduleControlView(
                    scheduleResult: scheduleAsync.asData?.value,
                    controller: controller,
                  )
                : const SizedBox(width: double.infinity), // This takes up no height when collapsed
          ),
          Expanded(
            child: scheduleAsync.when(
              data: (scheduleResult) {
                if (scheduleResult.scheduledCourses.isEmpty) {
                  return _buildNoScheduleFound(scaleConfig, theme);
                }
                return _ScheduleSuccessView(scheduleResult: scheduleResult);
              },
              loading: () => const SizedBox.shrink(),
              error: (err, stack) =>
                  _buildErrorState(scaleConfig, err.toString(), theme),
            ),
          ),
        ],
      ),
    );

    if (isDarkMode) {
      return GradientScaffold(appBar: appBar, body: bodyContent);
    } else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        body: bodyContent,
      );
    }
  }

  Widget _buildErrorState(
      ScaleConfig scaleConfig, String error, ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(scaleConfig.scale(24.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 60),
            const SizedBox(height: 16),
            Text(
              'generate_schedule_failed_title'.tr,
              style:
                  theme.textTheme.titleLarge?.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoScheduleFound(ScaleConfig scaleConfig, ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(scaleConfig.scale(24.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: AppColors.accent, size: 60),
            const SizedBox(height: 16),
            Text(
              'no_schedule_found_title'.tr,
              style:
                  theme.textTheme.titleLarge?.copyWith(color: AppColors.accent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'no_schedule_found_desc'.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _showPriorityListDialog(
    BuildContext context,
    WidgetRef ref,
    ScheduleController controller,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final scaleConfig = ScaleConfig(context);
            final subjectsAsync = ref.watch(prioritizedSubjectsProvider);
            final togglingSubjectId = ref.watch(togglingSubjectIdProvider);
            final theme = Theme.of(context);

            return AlertDialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              content: GlassCard(
                borderRadius: BorderRadius.circular(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: scaleConfig.heightPercentage(0.75)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'priority_dialog_title'.tr,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(color: AppColors.primary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'priority_dialog_recommendation'.tr,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.orangeAccent),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'priority_dialog_banned_reason'.tr,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.error.withOpacity(0.8)),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: subjectsAsync.when(
                            loading: () => Center(
                                child: Lottie.asset('assets/5loading.json',
                                    width: 100)),
                            error: (err, st) => Center(
                                child: Text('error_generic'
                                    .trParams({'error': err.toString()}))),
                            data: (subjects) {
                              if (subjects.isEmpty) {
                                return Center(
                                    child: Text('no_subjects_to_display'.tr,
                                        style: theme.textTheme.bodyMedium));
                              }
                              return SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Text('priority_dialog_order_hint'.tr,
                                        style: theme.textTheme.labelLarge),
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 12.0),
                                          child: Container(
                                            width: 3,
                                            height: subjects.length * 56.0,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    AppColors.primary,
                                                    AppColors.accent,
                                                    Colors.orangeAccent,
                                                    AppColors.error,
                                                  ],
                                                  stops: [
                                                    0.0,
                                                    0.4,
                                                    0.7,
                                                    1.0
                                                  ]),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: subjects.map((subject) {
                                              final subjectId =
                                                  subject.subject['id'];
                                              final isBanned = subject.isBanned;
                                              final isToggling =
                                                  togglingSubjectId ==
                                                      subjectId;
                                              return ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                leading: Text(
                                                    "${subjects.indexOf(subject) + 1}."),
                                                title: Text(
                                                    subject.subject['name']),
                                                trailing: isToggling
                                                    ? const SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child:
                                                            CircularProgressIndicator(
                                                                strokeWidth:
                                                                    2.5))
                                                    : Switch(
                                                        value: !isBanned,
                                                        onChanged: (newValue) {
                                                          controller
                                                              .setSubjectBannedStatus(
                                                                  subjectId,
                                                                  shouldBeBanned:
                                                                      !newValue);
                                                        },
                                                        activeColor:
                                                            AppColors.primary,
                                                      ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: CustomButton(
                            onPressed: () => Navigator.of(context).pop(),
                            text: 'close_button'.tr,
                            gradient: AppColors.accentGradient,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ScheduleSuccessView extends ConsumerWidget {
  final ScheduleResult scheduleResult;
  const _ScheduleSuccessView({required this.scheduleResult});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = context.scaleConfig;
    final currentView = ref.watch(scheduleViewProvider);
    return Padding(
      // --- THE KEY FIX IS HERE ---
      // Apply the bottom padding here, inside the Expanded area.
      padding: EdgeInsets.fromLTRB(
        scaleConfig.scale(12),
        scaleConfig.scale(10),
        scaleConfig.scale(12),
        kBottomNavigationBarHeight + 20, // Add padding for the nav bar
      ),
      child: switch (currentView) {
        ScheduleView.list => ScheduleListView(scheduleResult: scheduleResult),
        ScheduleView.table => ScheduleTableView(scheduleResult: scheduleResult),
        ScheduleView.calendar =>
          ScheduleAgendaView(scheduleResult: scheduleResult),
        ScheduleView.dots => ScheduleDotsView(scheduleResult: scheduleResult),
      },
    );
  }
}