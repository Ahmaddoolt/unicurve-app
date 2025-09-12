import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/schedule_models.dart';
import 'dart:math';

class ScheduleTableView extends StatelessWidget {
  final ScheduleResult scheduleResult;

  const ScheduleTableView({super.key, required this.scheduleResult});

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
    final double minHourHeight = scaleConfig.tabletScale(50.0);
    final double maxHourHeight = scaleConfig.tabletScale(70.0);
    final double minDayColumnWidth = scaleConfig.widthPercentage(0.15);
    final double maxDayColumnWidth = scaleConfig.widthPercentage(0.25);
    final double timeColumnWidth = scaleConfig.widthPercentage(0.15);
    final double headerHeight = scaleConfig.tabletScale(30.0);

    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;

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
    final totalHours = maxHour - minHour;
    final activeDays =
        allSlots.map((s) => s['day_of_week'] as String).toSet().toList()
          ..sort((a, b) => dayMap[a]!.compareTo(dayMap[b]!));

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - timeColumnWidth;
        final dayColumnWidth = (availableWidth / activeDays.length).clamp(
          minDayColumnWidth,
          maxDayColumnWidth,
        );
        final availableHeight = constraints.maxHeight - headerHeight;
        final hourHeight = (availableHeight / totalHours).clamp(
          minHourHeight,
          maxHourHeight,
        );
        final totalGridHeight = headerHeight + (totalHours * hourHeight);
        final totalGridWidth =
            timeColumnWidth + (activeDays.length * dayColumnWidth);

        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SizedBox(
                width: totalGridWidth,
                height: totalGridHeight,
                child: Stack(
                  children: [
                    Container(
                      color: darkerColor,
                      child: _buildGrid(
                        context,
                        minHour,
                        totalHours,
                        hourHeight,
                        timeColumnWidth,
                        activeDays,
                        dayColumnWidth,
                        headerHeight,
                      ),
                    ),
                    ...allSlots.map((slot) {
                      final day = slot['day_of_week'];
                      if (!activeDays.contains(day)) {
                        return const SizedBox.shrink();
                      }

                      final dayIndex = activeDays.indexOf(day);

                      final startMinutes = _timeToMinutes(slot['start_time']);
                      var endMinutes = _timeToMinutes(slot['end_time']);
                      if (endMinutes == 0 && startMinutes > 0) {
                        endMinutes = 24 * 60;
                      }
                      final durationMinutes = endMinutes - startMinutes;
                      if (durationMinutes <= 0) return const SizedBox.shrink();

                      final topOffset =
                          ((startMinutes - (minHour * 60)) / 60) * hourHeight;
                      final top = topOffset + headerHeight;
                      final height = (durationMinutes / 60) * hourHeight;

                      final startOffset =
                          timeColumnWidth + (dayIndex * dayColumnWidth);

                      final baseColor = _generateColor(slot['subject_id']);
                      final slotColor =
                          slot['schedule_type'] == 'PRACTICAL'
                              // ignore: deprecated_member_use
                              ? baseColor.withOpacity(0.5)
                              // ignore: deprecated_member_use
                              : baseColor.withOpacity(0.9);

                      return Positioned(
                        top: top,
                        left: isRTL ? null : startOffset + scaleConfig.scale(4),
                        right:
                            isRTL ? startOffset + scaleConfig.scale(4) : null,
                        width: dayColumnWidth - scaleConfig.scale(8),
                        height: height,
                        child: Card(
                          color: slotColor,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              scaleConfig.scale(8),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(scaleConfig.scale(6.0)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Text(
                                    slot['subject_code'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryTextColor,
                                      fontSize: scaleConfig.tabletScaleText(12),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    slot['subject_name'],
                                    style: TextStyle(
                                      color: primaryTextColor,
                                      fontSize: scaleConfig.tabletScaleText(10),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                const Spacer(),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Text(
                                    slot['schedule_type'] == 'PRACTICAL'
                                        ? 'table_lab'.tr
                                        : 'table_lecture'.tr,
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: primaryTextColor,
                                      fontSize: scaleConfig.tabletScaleText(9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(
    BuildContext context,
    int startHour,
    int totalHours,
    double hourHeight,
    double timeColumnWidth,
    List<String> activeDays,
    double dayColumnWidth,
    double headerHeight,
  ) {
    final scaleConfig = ScaleConfig(context);
    final bool isRTL = Get.locale?.languageCode == 'ar';
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
          height: headerHeight,
          child: Row(
            children: [
              SizedBox(width: timeColumnWidth),
              ...activeDays.map(
                (day) => SizedBox(
                  width: dayColumnWidth,
                  child: Center(
                    child: Text(
                      shortDayNames[day] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                        fontSize: scaleConfig.tabletScaleText(14),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: timeColumnWidth,
                child: Column(
                  children: List.generate(totalHours, (index) {
                    final hour = startHour + index;
                    return SizedBox(
                      height: hourHeight,
                      child: Transform.translate(
                        offset: const Offset(0, -7),
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                            fontSize: scaleConfig.tabletScaleText(10),
                            color: secondaryTextColor,
                          ),
                          textAlign: isRTL ? TextAlign.end : TextAlign.start,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ...List.generate(totalHours + 1, (index) {
                      return Positioned(
                        top: index * hourHeight,
                        left: 0,
                        right: 0,
                        child: Container(height: 1, color: lighterColor),
                      );
                    }),
                    ...List.generate(activeDays.length, (index) {
                      return Positioned(
                        top: 0,
                        bottom: 0,
                        left: index * dayColumnWidth,
                        child: Container(width: 1, color: lighterColor),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
