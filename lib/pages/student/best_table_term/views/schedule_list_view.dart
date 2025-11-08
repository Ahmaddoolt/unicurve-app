// lib/pages/student/best_table_term/views/schedule_list_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/schedule_models.dart';

class ScheduleListView extends StatelessWidget {
  final ScheduleResult scheduleResult;
  const ScheduleListView({super.key, required this.scheduleResult});

  @override
  Widget build(BuildContext context) {
    final scaleConfig = ScaleConfig(context);
    final theme = Theme.of(context);

    return ListView(
      // Add padding to prevent the list from touching the screen edges
      padding: const EdgeInsets.only(bottom: 24),
      children: scheduleResult.scheduledCourses.map((course) {
        final theoretical =
            course.schedules.where((s) => s['schedule_type'] == 'THEORETICAL');
        final practical =
            course.schedules.where((s) => s['schedule_type'] == 'PRACTICAL');

        // --- THE KEY FIX: Replacing Card with GlassCard ---
        return GlassCard(
          margin: EdgeInsets.only(bottom: scaleConfig.scale(12)),
          child: ExpansionTile(
            // Use themed colors for better adaptability
            iconColor: AppColors.primary,
            collapsedIconColor: theme.textTheme.bodyMedium?.color,
            shape: const Border(), // Remove the default border inside
            title: Text(
              course.subject['name'],
              style: theme.textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${course.subject['code']} - ${'hours_label'.trParams({
                    'hours': course.subject['hours'].toString()
                  })}',
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  scaleConfig.scale(16),
                  0,
                  scaleConfig.scale(16),
                  scaleConfig.scale(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: theme.dividerColor),
                    Text(
                      'list_group_code'
                          .trParams({'code': course.group['group_code']}),
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: AppColors.accent),
                    ),
                    SizedBox(height: scaleConfig.scale(8)),
                    if (theoretical.isNotEmpty)
                      ...theoretical.map(
                        (slot) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            'list_schedule_lecture'.trParams({
                              'day': (slot['day_of_week'] as String).tr,
                              'start': (slot['start_time'] as String)
                                  .substring(0, 5),
                              'end':
                                  (slot['end_time'] as String).substring(0, 5),
                            }),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    if (practical.isNotEmpty)
                      ...practical.map(
                        (slot) => Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'list_schedule_lab'.trParams({
                              'day': (slot['day_of_week'] as String).tr,
                              'start': (slot['start_time'] as String)
                                  .substring(0, 5),
                              'end':
                                  (slot['end_time'] as String).substring(0, 5),
                            }),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
