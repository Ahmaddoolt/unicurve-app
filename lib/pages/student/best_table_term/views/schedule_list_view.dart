import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/schedule_models.dart';

class ScheduleListView extends StatelessWidget {
  final ScheduleResult scheduleResult;
  const ScheduleListView({super.key, required this.scheduleResult});

  @override
  Widget build(BuildContext context) {
    final scaleConfig = ScaleConfig(context);
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return ListView(
      children:
          scheduleResult.scheduledCourses.map((course) {
            final theoretical = course.schedules.where(
              (s) => s['schedule_type'] == 'THEORETICAL',
            );
            final practical = course.schedules.where(
              (s) => s['schedule_type'] == 'PRACTICAL',
            );
            return Card(
              elevation: 1,
              color: darkerColor,
              margin: EdgeInsets.only(bottom: scaleConfig.scale(12)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(scaleConfig.scale(10)),
              ),
              child: ExpansionTile(
                iconColor: AppColors.accent,
                collapsedIconColor: secondaryTextColor,
                title: Text(
                  course.subject['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                    fontSize: scaleConfig.tabletScaleText(15),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${course.subject['code']} - ${'hours_label'.trParams({'hours': course.subject['hours'].toString()})}',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: scaleConfig.tabletScaleText(12),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      scaleConfig.scale(16),
                      0,
                      scaleConfig.scale(16),
                      scaleConfig.scale(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: lighterColor),
                        Text(
                          'list_group_code'.trParams({
                            'code': course.group['group_code'].toString(),
                          }),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                            fontSize: scaleConfig.tabletScaleText(13),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: scaleConfig.scale(8)),
                        if (theoretical.isNotEmpty) ...[
                          ...theoretical.map(
                            (slot) => Text(
                              'list_schedule_lecture'.trParams({
                                'day': slot['day_of_week'],
                                'start': slot['start_time'].substring(0, 5),
                                'end': slot['end_time'].substring(0, 5),
                              }),
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: scaleConfig.tabletScaleText(13),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (practical.isNotEmpty) ...[
                          ...practical.map(
                            (slot) => Text(
                              'list_schedule_lab'.trParams({
                                'day': slot['day_of_week'],
                                'start': slot['start_time'].substring(0, 5),
                                'end': slot['end_time'].substring(0, 5),
                              }),
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: scaleConfig.tabletScaleText(13),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
