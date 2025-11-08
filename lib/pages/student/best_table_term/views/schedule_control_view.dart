// lib/pages/student/best_table_term/views/schedule_control_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/glass_card.dart';
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

    // --- THIS IS THE KEY CHANGE: Using GlassCard as the main container ---
    return GlassCard(
      margin: EdgeInsets.symmetric(
        vertical: scaleConfig.scale(10),
        horizontal: scaleConfig.scale(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(scaleConfig.scale(12)),
        child: Column(
          children: [
            _ScheduleSummaryHeader(scheduleResult: scheduleResult),
            SizedBox(height: scaleConfig.scale(12)),
            _buildControlToggles(context, ref, controller),
            SizedBox(height: scaleConfig.scale(8)),
            _buildGeneratorOptions(context, ref, controller),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ARE REDESIGNED TO MATCH THE SCREENSHOT ---

  Widget _buildControlToggles(
    BuildContext context,
    WidgetRef ref,
    ScheduleController controller,
  ) {
    final scaleConfig = ScaleConfig(context);
    final theme = Theme.of(context);
    final selectedRank = ref.watch(scheduleRankProvider);
    final currentView = ref.watch(scheduleViewProvider);
    final List<ScheduleView> viewOrder = [
      ScheduleView.dots,
      ScheduleView.list,
      ScheduleView.table,
      ScheduleView.calendar,
    ];

    // Custom colors from the screenshot
    final Color selectedColor = theme.brightness == Brightness.dark
        ? const Color(0xFF10B981)
        : AppColors.primary;
    final Color selectedFillColor = theme.brightness == Brightness.dark
        ? const Color(0xFF047857)
        : AppColors.primary.withOpacity(0.2);

    return Column(
      children: [
        ToggleButtons(
          isSelected: [selectedRank == 0, selectedRank == 1, selectedRank == 2],
          onPressed: (index) => controller.setScheduleRank(index),
          color: theme.textTheme.bodyMedium?.color,
          selectedColor: selectedColor,
          fillColor: selectedFillColor,
          borderColor: Colors.transparent,
          selectedBorderColor: selectedColor,
          borderRadius: BorderRadius.circular(scaleConfig.scale(10)),
          constraints: BoxConstraints(
            minHeight: scaleConfig.tabletScale(38),
            minWidth: (scaleConfig.widthPercentage(0.9) - 32) /
                3, // Distribute width evenly
          ),
          children: [
            Text('rank_top1'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('rank_top2'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('rank_top3'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: scaleConfig.scale(10)),
        ToggleButtons(
          isSelected: viewOrder.map((view) => view == currentView).toList(),
          onPressed: (index) => controller.setScheduleView(viewOrder[index]),
          color: theme.textTheme.bodyMedium?.color,
          selectedColor: selectedColor,
          fillColor: selectedFillColor,
          borderColor: Colors.transparent,
          selectedBorderColor: selectedColor,
          borderRadius: BorderRadius.circular(scaleConfig.scale(10)),
          constraints: BoxConstraints(
            minHeight: scaleConfig.tabletScale(50),
            minWidth: (scaleConfig.widthPercentage(0.9) - 32) /
                4, // Distribute width evenly
          ),
          children: [
            _ViewToggleIcon(icon: Icons.apps, label: 'view_dots'.tr),
            _ViewToggleIcon(icon: Icons.list, label: 'view_list'.tr),
            _ViewToggleIcon(icon: Icons.grid_on, label: 'view_table'.tr),
            _ViewToggleIcon(
                icon: Icons.view_timeline_outlined, label: 'view_timeline'.tr),
          ],
        ),
      ],
    );
  }

  Widget _buildGeneratorOptions(
    BuildContext context,
    WidgetRef ref,
    ScheduleController controller,
  ) {
    final scaleConfig = ScaleConfig(context);
    final theme = Theme.of(context);
    final selectedMaxHours = ref.watch(maxHoursProvider);
    final minimizeDays = ref.watch(minimizeDaysProvider);
    final List<int> hourOptions = [9, 12, 18, 21];

    final Color selectedColor = theme.brightness == Brightness.dark
        ? const Color(0xFF10B981)
        : AppColors.primary;
    final Color selectedFillColor = theme.brightness == Brightness.dark
        ? const Color(0xFF047857)
        : AppColors.primary.withOpacity(0.2);

    return Column(
      children: [
        ToggleButtons(
          isSelected: hourOptions.map((h) => selectedMaxHours == h).toList(),
          onPressed: (index) => controller.setMaxHours(hourOptions[index]),
          color: theme.textTheme.bodyMedium?.color,
          selectedColor: selectedColor,
          fillColor: selectedFillColor,
          borderColor: Colors.transparent,
          selectedBorderColor: selectedColor,
          borderRadius: BorderRadius.circular(scaleConfig.scale(10)),
          constraints: BoxConstraints(
            minHeight: scaleConfig.tabletScale(38),
            minWidth: (scaleConfig.widthPercentage(0.9) - 32) / 4,
          ),
          children: [
            Text('option_upto_9_hours'.tr,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 11)),
            Text('option_upto_12_hours'.tr,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 11)),
            Text('option_upto_18_hours'.tr,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 11)),
            Text('option_upto_21_hours'.tr,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 10),
        ToggleButtons(
          isSelected: [minimizeDays, !minimizeDays],
          onPressed: (index) => controller.setMinimizeDays(index == 0),
          color: theme.textTheme.bodyMedium?.color,
          selectedColor: selectedColor,
          fillColor: selectedFillColor,
          borderColor: Colors.transparent,
          selectedBorderColor: selectedColor,
          borderRadius: BorderRadius.circular(scaleConfig.scale(10)),
          constraints: BoxConstraints(
            minHeight: scaleConfig.tabletScale(38),
            minWidth: (scaleConfig.widthPercentage(0.9) - 32) / 2,
          ),
          children: [
            Text('option_prefer_min_days'.tr,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('option_ignore_days'.tr,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

class _ScheduleSummaryHeader extends StatelessWidget {
  final ScheduleResult? scheduleResult;
  const _ScheduleSummaryHeader({required this.scheduleResult});

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    final uniqueDays = scheduleResult?.uniqueDays;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleConfig.scale(4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _InfoChip(
            icon: Icons.school_outlined,
            value: 'summary_lectures'.trParams({
              'count':
                  scheduleResult?.scheduledCourses.length.toString() ?? '0',
            }),
          ),
          _InfoChip(
            icon: Icons.timer_outlined,
            value: 'summary_hours'.trParams({
              'count': scheduleResult?.totalHours.toString() ?? '0',
            }),
          ),
          if (uniqueDays != null)
            _InfoChip(
              icon: Icons.date_range_outlined,
              value: 'summary_days'.trParams({'count': uniqueDays.toString()}),
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
    final theme = Theme.of(context);
    final scaleConfig = context.scaleConfig;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            color: theme.colorScheme.onSurface, size: scaleConfig.scale(16)),
        SizedBox(width: scaleConfig.scale(6)),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
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
  const _ViewToggleIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleConfig.scale(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: scaleConfig.tabletScale(22)),
          SizedBox(height: scaleConfig.scale(2)),
          Text(
            label,
            style: TextStyle(
              fontSize: scaleConfig.scaleText(10),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
