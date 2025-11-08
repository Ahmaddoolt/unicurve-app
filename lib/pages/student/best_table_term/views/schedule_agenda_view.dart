// lib/pages/student/best_table_term/views/schedule_agenda_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/schedule_models.dart';
import 'dart:math';

class ScheduleAgendaView extends StatelessWidget {
  final ScheduleResult scheduleResult;
  const ScheduleAgendaView({super.key, required this.scheduleResult});

  Color _generateColor(int subjectId) =>
      Color((Random(subjectId).nextDouble() * 0xFFFFFF).toInt())
          .withOpacity(1.0);

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
    final theme = Theme.of(context);
    final isRTL = Get.locale?.languageCode == 'ar';
    final double minDayRowHeight = scaleConfig.tabletScale(50.0);
    final double maxDayRowHeight = scaleConfig.tabletScale(70.0);
    final double minHourColumnWidth = scaleConfig.widthPercentage(0.15);
    final double maxHourColumnWidth = scaleConfig.widthPercentage(0.25);
    final double timeHeaderHeight = scaleConfig.tabletScale(30.0);
    final double dayLabelWidth = scaleConfig.widthPercentage(0.15);

    final Map<String, int> dayMap = isRTL
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
        if (endMinutes == 0 && startMinutes > 0) endMinutes = 24 * 60;

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
    maxHour = maxHour.clamp(minHour + 1, 24);
    final totalHoursInView = maxHour - minHour;
    final activeDays = allSlots
        .map((s) => s['day_of_week'] as String)
        .toSet()
        .toList()
      ..sort((a, b) => dayMap[a]!.compareTo(dayMap[b]!));

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _CourseLegend(
                scheduleResult: scheduleResult, generateColor: _generateColor),
            SizedBox(height: scaleConfig.scale(10)),
            SizedBox(
              height: 500,
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
                      color: Colors.transparent,
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

                            final startMinutes =
                                _timeToMinutes(slot['start_time']);
                            var endMinutes = _timeToMinutes(slot['end_time']);
                            if (endMinutes == 0 && startMinutes > 0)
                              endMinutes = 24 * 60;

                            final durationMinutes = endMinutes - startMinutes;
                            if (durationMinutes <= 0)
                              return const SizedBox.shrink();

                            final top =
                                timeHeaderHeight + (dayIndex * dayRowHeight);
                            final startOffset = dayLabelWidth +
                                (((startMinutes / 60) - minHour) *
                                    hourColumnWidth);
                            final width =
                                (durationMinutes / 60) * hourColumnWidth;

                            final baseColor =
                                _generateColor(slot['subject_id']);
                            final slotColor =
                                slot['schedule_type'] == 'PRACTICAL'
                                    ? baseColor.withOpacity(0.5)
                                    : baseColor;

                            return Positioned(
                              top: top + scaleConfig.scale(10),
                              left: isRTL
                                  ? null
                                  : startOffset + scaleConfig.scale(5),
                              right: isRTL
                                  ? startOffset + scaleConfig.scale(5)
                                  : null,
                              height: dayRowHeight - scaleConfig.scale(20),
                              width: width - scaleConfig.scale(10),
                              child: GlassCard(
                                color: slotColor.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(
                                    scaleConfig.scale(15)),
                                child: Center(
                                  child: Text(
                                    slot['subject_code'],
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
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
      double timeHeaderHeight) {
    final theme = Theme.of(context);

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
                      style: theme.textTheme.bodySmall,
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
              border: Border(
                  top: BorderSide(color: theme.dividerColor, width: 1.0)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: dayLabelWidth,
                  child: Center(
                    child: Text(
                      shortDayNames[day] ?? day,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                ...List.generate(totalHours, (index) {
                  return Container(
                    width: hourColumnWidth,
                    decoration: BoxDecoration(
                      border: Border(
                          left: BorderSide(
                              color: theme.dividerColor, width: 1.0)),
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

// --- THIS IS THE KEY FIX ---
// The Course Legend is now a collapsible ExpansionTile inside the GlassCard.
class _CourseLegend extends StatelessWidget {
  final ScheduleResult scheduleResult;
  final Color Function(int) generateColor;

  const _CourseLegend(
      {required this.scheduleResult, required this.generateColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: ExpansionTile(
        title: Text('agenda_course_legend'.tr,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: AppColors.primary)),
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        childrenPadding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 12.0),
        iconColor: AppColors.primary,
        collapsedIconColor: theme.textTheme.bodyMedium?.color,
        shape: const Border(), // Remove the default border inside
        children: [
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 8),
          ...scheduleResult.scheduledCourses.map((course) {
            final hasPractical =
                course.schedules.any((s) => s['schedule_type'] == 'PRACTICAL');
            final baseColor = generateColor(course.subject['id']);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      course.subject['name'],
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('agenda_lecture'.tr, style: theme.textTheme.bodySmall),
                  Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                          color: baseColor, shape: BoxShape.circle)),
                  if (hasPractical) ...[
                    const SizedBox(width: 8),
                    Text('agenda_lab'.tr, style: theme.textTheme.bodySmall),
                    Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                            color: baseColor.withOpacity(0.5),
                            shape: BoxShape.circle)),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
