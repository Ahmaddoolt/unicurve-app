import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
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

final scheduleViewProvider = StateProvider<ScheduleView>(
  (ref) => ScheduleView.dots,
);
final scheduleRankProvider = StateProvider<int>((ref) => 0);
final isRefreshingProvider = StateProvider<bool>((ref) => false);

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
    final scaleConfig = ScaleConfig(context);
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: lighterColor,
      appBar: AppBar(
        title: Text('optimal_schedule_title'.tr),
        centerTitle: true,
        backgroundColor: darkerColor,
        titleTextStyle: TextStyle(
          color: primaryTextColor,
          fontWeight: FontWeight.bold,
          fontSize: scaleConfig.tabletScaleText(18),
        ),
        actions: [
          IconButton(
            tooltip: 'view_subjects_list_tooltip'.tr,
            icon: const Icon(
              Icons.format_list_numbered,
              color: AppColors.accent,
            ),
            onPressed: () => _showPriorityListDialog(context, ref, controller),
          ),
          Consumer(
            builder: (context, ref, child) {
              final isRefreshing = ref.watch(isRefreshingProvider);
              return isRefreshing
                  ? Padding(
                    padding: EdgeInsets.only(right: scaleConfig.scale(14.0)),
                    child: SizedBox(
                      width: scaleConfig.tabletScale(20),
                      height: scaleConfig.tabletScale(20),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                  : IconButton(
                    tooltip: 'refresh_data_tooltip'.tr,
                    icon: const Icon(Icons.sync, color: AppColors.primary),
                    onPressed: () => controller.refreshSchedules(selectedRank),
                  );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ScheduleControlView(
            scheduleResult: scheduleAsync.asData?.value,
            controller: controller,
          ),
          Expanded(
            child: scheduleAsync.when(
              loading:
                  () => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                        SizedBox(height: scaleConfig.scale(20)),
                        Text(
                          'generating_schedule_loading'.tr,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: scaleConfig.tabletScaleText(16),
                          ),
                        ),
                      ],
                    ),
                  ),
              error:
                  (err, stack) => Center(
                    child: Padding(
                      padding: EdgeInsets.all(scaleConfig.scale(24.0)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: scaleConfig.tabletScale(60),
                          ),
                          SizedBox(height: scaleConfig.scale(16)),
                          Text(
                            'generate_schedule_failed_title'.tr,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: scaleConfig.tabletScaleText(18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: scaleConfig.scale(8)),
                          Text(
                            '$err',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: scaleConfig.tabletScaleText(14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              data: (scheduleResult) {
                if (scheduleResult.scheduledCourses.isEmpty) {
                  return _buildNoScheduleFound(scaleConfig);
                }
                return _ScheduleSuccessView(scheduleResult: scheduleResult);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoScheduleFound(ScaleConfig scaleConfig) {
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(scaleConfig.scale(24.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: AppColors.accent,
              size: scaleConfig.tabletScale(60),
            ),
            SizedBox(height: scaleConfig.scale(16)),
            Text(
              'no_schedule_found_title'.tr,
              style: TextStyle(
                color: AppColors.accent,
                fontSize: scaleConfig.tabletScaleText(18),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: scaleConfig.scale(8)),
            Text(
              'no_schedule_found_desc'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: scaleConfig.tabletScaleText(14),
              ),
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
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final scaleConfig = ScaleConfig(context);
            final subjectsAsync = ref.watch(prioritizedSubjectsProvider);
            final togglingSubjectId = ref.watch(togglingSubjectIdProvider);

            return AlertDialog(
              backgroundColor: darkerColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
              ),
              titlePadding: EdgeInsets.only(
                top: scaleConfig.scale(16),
                left: scaleConfig.scale(24),
                right: scaleConfig.scale(24),
              ),
              title: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'priority_dialog_title'.tr,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: scaleConfig.tabletScaleText(18),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: scaleConfig.scale(8)),
                    Text(
                      'priority_dialog_recommendation'.tr,
                      style: TextStyle(
                        color: const Color.fromARGB(
                          255,
                          211,
                          159,
                          0,
                          // ignore: deprecated_member_use
                        ).withOpacity(0.9),
                        fontSize: scaleConfig.tabletScaleText(14),
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: scaleConfig.scale(8)),
                    Text(
                      'priority_dialog_banned_reason'.tr,
                      style: TextStyle(
                        // ignore: deprecated_member_use
                        color: AppColors.error.withOpacity(0.9),
                        fontSize: scaleConfig.tabletScaleText(14),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: scaleConfig.scale(20),
                vertical: scaleConfig.scale(12),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: subjectsAsync.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (err, st) => Text(
                        'error_generic'.trParams({'error': err.toString()}),
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: scaleConfig.tabletScaleText(14),
                        ),
                      ),
                  data: (subjects) {
                    if (subjects.isEmpty) {
                      return Center(
                        child: Text(
                          'no_subjects_to_display'.tr,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: scaleConfig.tabletScaleText(14),
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: scaleConfig.scale(8),
                              left: scaleConfig.scale(4),
                            ),
                            child: Center(
                              child: Text(
                                'priority_dialog_order_hint'.tr,
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: scaleConfig.tabletScaleText(13),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  top: scaleConfig.scale(6),
                                ),
                                child: Container(
                                  width: 2,
                                  height:
                                      subjects.length * scaleConfig.scale(70),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppColors.primary,
                                        // ignore: deprecated_member_use
                                        AppColors.primary.withOpacity(0.6),
                                        // ignore: deprecated_member_use
                                        AppColors.primary.withOpacity(0.6),
                                        // ignore: deprecated_member_use
                                        AppColors.accent.withOpacity(0.6),
                                        // ignore: deprecated_member_use
                                        AppColors.accent.withOpacity(0.6),
                                        // ignore: deprecated_member_use
                                        AppColors.error.withOpacity(0.6),
                                        // ignore: deprecated_member_use
                                        AppColors.error.withOpacity(0.6),
                                        AppColors.error,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: subjects.length,
                                  itemBuilder: (context, index) {
                                    final subject = subjects[index];
                                    final subjectId = subject.subject['id'];
                                    final isBanned = subject.isBanned;
                                    final isToggling =
                                        togglingSubjectId == subjectId;

                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: scaleConfig.scale(4),
                                      ),
                                      child: Material(
                                        color: darkerColor,
                                        borderRadius: BorderRadius.circular(
                                          scaleConfig.scale(8),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(
                                            scaleConfig.scale(10.0),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                "${index + 1}.",
                                                style: TextStyle(
                                                  color: secondaryTextColor,
                                                  fontSize: scaleConfig
                                                      .tabletScaleText(14),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  subject.subject['name'],
                                                  style: TextStyle(
                                                    color:
                                                        isBanned
                                                            ? secondaryTextColor
                                                            // ignore: deprecated_member_use
                                                            ?.withOpacity(0.5)
                                                            : secondaryTextColor,
                                                    fontSize: scaleConfig
                                                        .tabletScaleText(14),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isToggling)
                                                SizedBox(
                                                  width: scaleConfig
                                                      .tabletScale(24),
                                                  height: scaleConfig
                                                      .tabletScale(24),
                                                  child:
                                                      const CircularProgressIndicator(
                                                        strokeWidth: 2.5,
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                )
                                              else
                                                Switch(
                                                  value: !isBanned,
                                                  onChanged: (newValue) {
                                                    final shouldBeBanned =
                                                        !newValue;
                                                    controller
                                                        .setSubjectBannedStatus(
                                                          subjectId,
                                                          shouldBeBanned:
                                                              shouldBeBanned,
                                                        );
                                                  },
                                                  activeColor:
                                                      AppColors.primary,
                                                  inactiveThumbColor:
                                                      secondaryTextColor,
                                                  inactiveTrackColor:
                                                      secondaryTextColor
                                                      // ignore: deprecated_member_use
                                                      ?.withOpacity(0.3),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
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
              actionsPadding: EdgeInsets.only(
                bottom: scaleConfig.scale(8),
                right: scaleConfig.scale(16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.accent,
                    padding: EdgeInsets.symmetric(
                      horizontal: scaleConfig.scale(16),
                      vertical: scaleConfig.scale(8),
                    ),
                    textStyle: TextStyle(
                      fontSize: scaleConfig.tabletScaleText(14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text('close_button'.tr),
                ),
              ],
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
    final scaleConfig = ScaleConfig(context);
    final currentView = ref.watch(scheduleViewProvider);
    return Column(
      children: [
        SizedBox(height: scaleConfig.scale(10)),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: scaleConfig.scale(12)),
            child: switch (currentView) {
              ScheduleView.list => ScheduleListView(
                scheduleResult: scheduleResult,
              ),
              ScheduleView.table => ScheduleTableView(
                scheduleResult: scheduleResult,
              ),
              ScheduleView.calendar => ScheduleAgendaView(
                scheduleResult: scheduleResult,
              ),
              ScheduleView.dots => ScheduleDotsView(
                scheduleResult: scheduleResult,
              ),
            },
          ),
        ),
      ],
    );
  }
}
