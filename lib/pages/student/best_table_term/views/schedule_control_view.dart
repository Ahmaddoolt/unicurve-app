import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/schedule_models.dart';
import 'package:unicurve/pages/student/best_table_term/views/best_schedule_page.dart';
import 'package:unicurve/pages/student/best_table_term/controllers/schedule_controller.dart';
import 'package:unicurve/pages/student/best_table_term/providers/schedule_generator_provider.dart';

class ScheduleControlView extends ConsumerWidget {
  final ScheduleResult? scheduleResult;
  final ScheduleController controller;

  const ScheduleControlView({
    super.key,
    required this.scheduleResult,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = ScaleConfig(context);
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: scaleConfig.scale(10),
        horizontal: scaleConfig.scale(12),
      ),
      child: Card(
        elevation: 2,
        color: darkerColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        ),
        child: Column(
          children: [
            _ScheduleSummaryHeader(scheduleResult: scheduleResult),
            _buildControlToggles(context, ref, controller),
            _buildGeneratorOptions(context, ref, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildControlToggles(
    BuildContext context,
    WidgetRef ref,
    ScheduleController controller,
  ) {
    final scaleConfig = ScaleConfig(context);
    final selectedRank = ref.watch(scheduleRankProvider);
    final currentView = ref.watch(scheduleViewProvider);
    final List<ScheduleView> viewOrder = [
      ScheduleView.dots,
      ScheduleView.list,
      ScheduleView.table,
      ScheduleView.calendar,
    ];
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        scaleConfig.scale(8),
        0,
        scaleConfig.scale(8),
        scaleConfig.scale(8),
      ),
      child: Column(
        children: [
          ToggleButtons(
            isSelected: [
              selectedRank == 0,
              selectedRank == 1,
              selectedRank == 2,
            ],
            onPressed: (index) => controller.setScheduleRank(index),
            color: secondaryTextColor,
            selectedColor: AppColors.primary,
            // ignore: deprecated_member_use
            fillColor: AppColors.primary.withOpacity(0.2),
            borderColor: Colors.transparent,
            selectedBorderColor: AppColors.primary,
            borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
            constraints: BoxConstraints(
              minHeight: scaleConfig.tabletScale(36),
              minWidth: scaleConfig.widthPercentage(0.25),
            ),
            children: [
              Text(
                'rank_top1'.tr,
                style: TextStyle(
                  fontSize: scaleConfig.tabletScaleText(12),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'rank_top2'.tr,
                style: TextStyle(
                  fontSize: scaleConfig.tabletScaleText(12),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'rank_top3'.tr,
                style: TextStyle(
                  fontSize: scaleConfig.tabletScaleText(12),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: scaleConfig.scale(8)),
          ToggleButtons(
            isSelected: viewOrder.map((view) => view == currentView).toList(),
            onPressed: (index) => controller.setScheduleView(viewOrder[index]),
            color: secondaryTextColor,
            selectedColor: AppColors.primary,
            // ignore: deprecated_member_use
            fillColor: AppColors.primary.withOpacity(0.2),
            borderColor: Colors.transparent,
            selectedBorderColor: AppColors.primary,
            borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
            constraints: BoxConstraints(
              minHeight: scaleConfig.tabletScale(40),
              minWidth: scaleConfig.widthPercentage(0.20),
            ),
            children: [
              _ViewToggleIcon(
                icon: Icons.apps,
                label: 'view_dots'.tr,
                isSelected: currentView == ScheduleView.dots,
              ),
              _ViewToggleIcon(
                icon: Icons.list,
                label: 'view_list'.tr,
                isSelected: currentView == ScheduleView.list,
              ),
              _ViewToggleIcon(
                icon: Icons.grid_on,
                label: 'view_table'.tr,
                isSelected: currentView == ScheduleView.table,
              ),
              _ViewToggleIcon(
                icon: Icons.view_timeline_outlined,
                label: 'view_timeline'.tr,
                isSelected: currentView == ScheduleView.calendar,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratorOptions(
    BuildContext context,
    WidgetRef ref,
    ScheduleController controller,
  ) {
    final scaleConfig = ScaleConfig(context);
    final selectedMaxHours = ref.watch(maxHoursProvider);
    final minimizeDays = ref.watch(minimizeDaysProvider);

    final double fontSize = scaleConfig.tabletScaleText(12);
    final double minHeight = scaleConfig.tabletScale(36);
    final double minWidth = scaleConfig.widthPercentage(0.40);
    final BorderRadius borderRadius = BorderRadius.circular(
      scaleConfig.scale(8),
    );

    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        scaleConfig.scale(16),
        scaleConfig.scale(8),
        scaleConfig.scale(16),
        scaleConfig.scale(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ToggleButtons(
                isSelected: [selectedMaxHours == 18, selectedMaxHours == 21],
                onPressed:
                    (index) => controller.setMaxHours(index == 0 ? 18 : 21),
                color: secondaryTextColor,
                selectedColor: AppColors.primary,
                // ignore: deprecated_member_use
                fillColor: AppColors.primary.withOpacity(0.2),
                borderColor: Colors.transparent,
                selectedBorderColor: AppColors.primary,
                borderRadius: borderRadius,
                constraints: BoxConstraints(
                  minWidth: minWidth,
                  minHeight: minHeight,
                ),
                children: [
                  Text(
                    'option_upto_18_hours'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                  Text(
                    'option_upto_21_hours'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ToggleButtons(
                isSelected: [minimizeDays, !minimizeDays],
                onPressed: (index) => controller.setMinimizeDays(index == 0),
                color: secondaryTextColor,
                selectedColor: AppColors.primary,
                // ignore: deprecated_member_use
                fillColor: AppColors.primary.withOpacity(0.2),
                borderColor: Colors.transparent,
                selectedBorderColor: AppColors.primary,
                borderRadius: borderRadius,
                constraints: BoxConstraints(
                  minWidth: minWidth,
                  minHeight: minHeight,
                ),
                children: [
                  Text(
                    'option_prefer_min_days'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                  Text(
                    'option_ignore_days'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleSummaryHeader extends StatelessWidget {
  final ScheduleResult? scheduleResult;
  const _ScheduleSummaryHeader({required this.scheduleResult});

  @override
  Widget build(BuildContext context) {
    final scaleConfig = ScaleConfig(context);
    final uniqueDays = scheduleResult?.uniqueDays;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        scaleConfig.scale(12),
        scaleConfig.scale(12),
        scaleConfig.scale(12),
        scaleConfig.scale(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (scheduleResult != null) ...[
            _InfoChip(
              icon: Icons.school_outlined,
              value: 'summary_lectures'.trParams({
                'count': scheduleResult!.scheduledCourses.length.toString(),
              }),
            ),
            _InfoChip(
              icon: Icons.timer_outlined,
              value: 'summary_hours'.trParams({
                'count': scheduleResult!.totalHours.toString(),
              }),
            ),
            if (uniqueDays != null)
              _InfoChip(
                icon: Icons.date_range_outlined,
                value: 'summary_days'.trParams({
                  'count': uniqueDays.toString(),
                }),
              ),
          ] else
            Text(
              'summary_title_fallback'.tr,
              style: TextStyle(
                fontSize: scaleConfig.tabletScaleText(16),
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String value;
  const _InfoChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    final scaleConfig = ScaleConfig(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.accent, size: scaleConfig.tabletScale(16)),
        SizedBox(width: scaleConfig.scale(4)),
        Text(
          value,
          style: TextStyle(
            color: primaryTextColor,
            fontSize: scaleConfig.tabletScaleText(14),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ViewToggleIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  const _ViewToggleIcon({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scaleConfig = ScaleConfig(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleConfig.scale(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: scaleConfig.tabletScale(20)),
          SizedBox(height: scaleConfig.scale(2)),
          Text(
            label,
            style: TextStyle(
              fontSize: scaleConfig.tabletScaleText(10),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
