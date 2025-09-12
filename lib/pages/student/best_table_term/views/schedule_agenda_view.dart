import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/schedule_models.dart';
import 'dart:math';

class ScheduleAgendaView extends StatelessWidget {
  final ScheduleResult scheduleResult;
  const ScheduleAgendaView({super.key, required this.scheduleResult});

  Color _generateColor(int subjectId) => Color(
    (Random(subjectId).nextDouble() * 0xFFFFFF).toInt(),
    // ignore: deprecated_member_use
  ).withOpacity(1.0);

  int _timeToMinutes(String time) {
    try {
      final p = time.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = ScaleConfig(context);
    final bool isRTL = Get.locale?.languageCode == 'ar';
    final double minDayRowHeight = scaleConfig.tabletScale(50.0);
    final double maxDayRowHeight = scaleConfig.tabletScale(70.0);
    final double minHourColumnWidth = scaleConfig.widthPercentage(0.15);
    final double maxHourColumnWidth = scaleConfig.widthPercentage(0.25);
    final double timeHeaderHeight = scaleConfig.tabletScale(30.0);
    final double dayLabelWidth = scaleConfig.widthPercentage(0.15);

    final Map<String, int> dayMap =
        isRTL
            ? {
              'Sunday': 0,
              'Monday': 1,
              'Tuesday': 2,
              'Wednesday': 3,
              'Thursday': 4,
              'Friday': 5,
              'Saturday': 6,
            }
            : {
              'Monday': 0,
              'Tuesday': 1,
              'Wednesday': 2,
              'Thursday': 3,
              'Friday': 4,
              'Saturday': 5,
              'Sunday': 6,
            };

    int minHour = 24, maxHour = 0;
    final allSlots = <Map<String, dynamic>>[];
    for (final course in scheduleResult.scheduledCourses) {
      for (final slot in course.schedules) {
        final startMinutes = _timeToMinutes(slot['start_time']);
        var endMinutes = _timeToMinutes(slot['end_time']);
        if (endMinutes == 0 && startMinutes > 0) {
          endMinutes = 24 * 60;
        }
        minHour = min(minHour, (startMinutes / 60).floor());
        maxHour = max(maxHour, (endMinutes / 60).ceil());
        allSlots.add({
          'subject_id': course.subject['id'],
          'subject_name': course.subject['name'],
          'subject_code': course.subject['code'],
          ...slot,
        });
      }
    }
    if (allSlots.isEmpty) return const SizedBox.shrink();
    minHour = minHour.clamp(0, 23);
    maxHour = maxHour.clamp(1, 24);
    if (maxHour <= minHour) {
      maxHour = minHour + 1;
    }
    final totalHoursInView = maxHour - minHour;
    final activeDays =
        allSlots.map((s) => s['day_of_week'] as String).toSet().toList()
          ..sort((a, b) => dayMap[a]!.compareTo(dayMap[b]!));

    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        children: [
          Card(
            color: darkerColor,
            child: Padding(
              padding: EdgeInsets.all(scaleConfig.scale(8.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'agenda_course_legend'.tr,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: scaleConfig.tabletScaleText(14),
                    ),
                  ),
                  Divider(color: lighterColor),
                  ...scheduleResult.scheduledCourses.map((course) {
                    final hasPractical = course.schedules.any(
                      (s) => s['schedule_type'] == 'PRACTICAL',
                    );
                    final baseColor = _generateColor(course.subject['id']);
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: scaleConfig.scale(2.0),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              course.subject['name'],
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: scaleConfig.tabletScaleText(12),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'agenda_lecture'.tr,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: scaleConfig.tabletScaleText(10),
                            ),
                          ),
                          Container(
                            width: scaleConfig.tabletScale(10),
                            height: scaleConfig.tabletScale(10),
                            margin: EdgeInsets.symmetric(
                              horizontal: scaleConfig.scale(4),
                            ),
                            decoration: BoxDecoration(
                              // ignore: deprecated_member_use
                              color: baseColor.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (hasPractical) ...[
                            SizedBox(width: scaleConfig.scale(8)),
                            Text(
                              'agenda_lab'.tr,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: scaleConfig.tabletScaleText(10),
                              ),
                            ),
                            Container(
                              width: scaleConfig.tabletScale(10),
                              height: scaleConfig.tabletScale(10),
                              margin: EdgeInsets.symmetric(
                                horizontal: scaleConfig.scale(4),
                              ),
                              decoration: BoxDecoration(
                                // ignore: deprecated_member_use
                                color: baseColor.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          SizedBox(height: scaleConfig.scale(10)),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth - dayLabelWidth;
                final hourColumnWidth = (availableWidth / totalHoursInView)
                    .clamp(minHourColumnWidth, maxHourColumnWidth);
                final availableHeight =
                    constraints.maxHeight - timeHeaderHeight;
                final dayRowHeight = (availableHeight / activeDays.length)
                    .clamp(minDayRowHeight, maxDayRowHeight);
                final totalGridWidth =
                    dayLabelWidth + (totalHoursInView * hourColumnWidth);

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: totalGridWidth,
                    color: darkerColor,
                    child: Stack(
                      children: [
                        _buildAgendaGrid(
                          context,
                          minHour,
                          totalHoursInView,
                          dayRowHeight,
                          hourColumnWidth,
                          activeDays,
                          dayLabelWidth,
                          timeHeaderHeight,
                        ),
                        ...allSlots.map((slot) {
                          final day = slot['day_of_week'];
                          final dayIndex = activeDays.indexOf(day);
                          if (dayIndex == -1) return const SizedBox.shrink();
                          final startMinutes = _timeToMinutes(
                            slot['start_time'],
                          );
                          var endMinutes = _timeToMinutes(slot['end_time']);
                          if (endMinutes == 0 && startMinutes > 0) {
                            endMinutes = 24 * 60;
                          }
                          final durationMinutes = endMinutes - startMinutes;
                          if (durationMinutes <= 0) {
                            return const SizedBox.shrink();
                          }

                          final top =
                              timeHeaderHeight + (dayIndex * dayRowHeight);
                          final startOffset =
                              dayLabelWidth +
                              (((startMinutes / 60) - minHour) *
                                  hourColumnWidth);
                          final width =
                              (durationMinutes / 60) * hourColumnWidth;

                          final baseColor = _generateColor(slot['subject_id']);
                          final slotColor =
                              slot['schedule_type'] == 'PRACTICAL'
                                  // ignore: deprecated_member_use
                                  ? baseColor.withOpacity(0.5)
                                  // ignore: deprecated_member_use
                                  : baseColor.withOpacity(0.9);

                          return Positioned(
                            top: top + scaleConfig.scale(10),
                            left:
                                isRTL
                                    ? null
                                    : startOffset + scaleConfig.scale(5),
                            right:
                                isRTL
                                    ? startOffset + scaleConfig.scale(5)
                                    : null,
                            height: dayRowHeight - scaleConfig.scale(20),
                            width: width - scaleConfig.scale(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: slotColor,
                                borderRadius: BorderRadius.circular(
                                  scaleConfig.scale(15),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  slot['subject_code'],
                                  style: TextStyle(
                                    color: primaryTextColor,
                                    fontSize: scaleConfig.tabletScaleText(10),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaGrid(
    BuildContext context,
    int startHour,
    int totalHours,
    double dayRowHeight,
    double hourColumnWidth,
    List<String> activeDays,
    double dayLabelWidth,
    double timeHeaderHeight,
  ) {
    final scaleConfig = ScaleConfig(context);
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    final Map<String, String> shortDayNames = {
      'Sunday': 'day_sun_short'.tr,
      'Monday': 'day_mon_short'.tr,
      'Tuesday': 'day_tue_short'.tr,
      'Wednesday': 'day_wed_short'.tr,
      'Thursday': 'day_thu_short'.tr,
      'Friday': 'day_fri_short'.tr,
      'Saturday': 'day_sat_short'.tr,
    };

    return Column(
      children: [
        SizedBox(
          height: timeHeaderHeight,
          child: Row(
            children: [
              SizedBox(width: dayLabelWidth),
              ...List.generate(totalHours, (index) {
                final hour = startHour + index;
                return SizedBox(
                  width: hourColumnWidth,
                  child: Center(
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                        fontSize: scaleConfig.tabletScaleText(10),
                        color: secondaryTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        ...activeDays.map((day) {
          return Container(
            height: dayRowHeight,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: lighterColor, width: 1.0)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: dayLabelWidth,
                  child: Center(
                    child: Text(
                      shortDayNames[day] ?? day,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                        fontSize: scaleConfig.tabletScaleText(12),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                ...List.generate(totalHours, (index) {
                  return Container(
                    width: hourColumnWidth,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: lighterColor, width: 1.0),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }
}
