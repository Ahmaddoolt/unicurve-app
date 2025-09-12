import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/schedule_models.dart';
import 'dart:math';

class ScheduleDotsView extends StatelessWidget {
  final ScheduleResult scheduleResult;
  const ScheduleDotsView({super.key, required this.scheduleResult});

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

    final Map<String, int> dayMap = {
      'Sunday': 0,
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
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

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: LayoutBuilder(
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
          final totalWidth =
              timeColumnWidth + (activeDays.length * dayColumnWidth);

          Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
          Color? secondaryTextColor =
              Theme.of(context).textTheme.bodyMedium?.color;

          return SingleChildScrollView(
            scrollDirection:
                totalWidth > constraints.maxWidth
                    ? Axis.horizontal
                    : Axis.vertical,
            child: Container(
              width: totalWidth,
              color: darkerColor,
              child: Stack(
                children: [
                  _buildDotsGrid(
                    context,
                    minHour,
                    totalHours,
                    hourHeight,
                    timeColumnWidth,
                    activeDays,
                    dayColumnWidth,
                    headerHeight,
                    isRTL,
                  ),
                  ...allSlots.expand((slot) {
                    final day = slot['day_of_week'];
                    if (!activeDays.contains(day)) return <Widget>[];
                    final dayIndex = activeDays.indexOf(day);
                    final startMinutes = _timeToMinutes(slot['start_time']);
                    var endMinutes = _timeToMinutes(slot['end_time']);
                    if (endMinutes == 0 && startMinutes > 0) {
                      endMinutes = 24 * 60;
                    }
                    final startHour = startMinutes ~/ 60;
                    final endHour = endMinutes ~/ 60;
                    final List<Widget> dots = [];
                    for (int hour = startHour; hour < endHour; hour++) {
                      final top =
                          ((hour - minHour) * hourHeight) + headerHeight;

                      final double startOffset =
                          timeColumnWidth + (dayIndex * dayColumnWidth);

                      final baseColor = _generateColor(slot['subject_id']);
                      final slotColor =
                          slot['schedule_type'] == 'PRACTICAL'
                              // ignore: deprecated_member_use
                              ? baseColor.withOpacity(0.5)
                              // ignore: deprecated_member_use
                              : baseColor.withOpacity(0.9);

                      dots.add(
                        Positioned(
                          top: top,
                          left: isRTL ? null : startOffset,
                          right: isRTL ? startOffset : null,
                          width: dayColumnWidth,
                          height: hourHeight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: scaleConfig.tabletScale(24),
                                height: scaleConfig.tabletScale(24),
                                decoration: BoxDecoration(
                                  color: slotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(height: scaleConfig.scale(4)),
                              Flexible(
                                child: Text(
                                  slot['subject_name'],
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: scaleConfig.tabletScaleText(10),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return dots;
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDotsGrid(
    BuildContext context,
    int startHour,
    int totalHours,
    double hourHeight,
    double timeColumnWidth,
    List<String> activeDays,
    double dayColumnWidth,
    double headerHeight,
    bool isRTL,
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
        ...List.generate(totalHours, (rowIndex) {
          final hour = startHour + rowIndex;
          return Container(
            height: hourHeight,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: lighterColor, width: 1.0)),
            ),
            child: Row(
              children: [
                Container(
                  width: timeColumnWidth,
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: const Offset(0, -7),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                        fontSize: scaleConfig.tabletScaleText(10),
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                ),
                ...List.generate(activeDays.length, (colIndex) {
                  return Container(
                    width: dayColumnWidth,
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
