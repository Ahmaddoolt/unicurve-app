// lib/pages/student/best_table_term/views/schedule_dots_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/schedule_models.dart';
import 'dart:math';

class ScheduleDotsView extends StatelessWidget {
  final ScheduleResult scheduleResult;
  const ScheduleDotsView({super.key, required this.scheduleResult});

  // Consistent color generation for subjects
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
    final bool isRTL = Get.locale?.languageCode == 'ar';
    final theme = Theme.of(context);

    // Define layout constants
    final double minHourHeight = scaleConfig.tabletScale(60.0);
    final double maxHourHeight = scaleConfig.tabletScale(80.0);
    final double timeColumnWidth = scaleConfig.widthPercentage(0.15);
    final double headerHeight = scaleConfig.tabletScale(30.0);

    final Map<String, int> dayMap = {
      'Sunday': 0,
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6
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
          'subject_code':
              course.subject['code'], // Important for the new design
          ...slot,
        });
      }
    }

    if (allSlots.isEmpty) return const SizedBox.shrink();
    minHour = minHour.clamp(0, 23);
    maxHour = maxHour.clamp(minHour + 1, 24);
    final totalHours = maxHour - minHour;

    final activeDays = allSlots
        .map((s) => s['day_of_week'] as String)
        .toSet()
        .toList()
      ..sort((a, b) => dayMap[a]!.compareTo(dayMap[b]!));

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        children: [
          _CourseLegend(
              scheduleResult: scheduleResult, generateColor: _generateColor),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth - timeColumnWidth;
                final dayColumnWidth = (availableWidth / activeDays.length);
                final availableHeight = constraints.maxHeight - headerHeight;
                final hourHeight = (availableHeight / totalHours)
                    .clamp(minHourHeight, maxHourHeight);
                final totalGridHeight =
                    headerHeight + (totalHours * hourHeight);

                return SingleChildScrollView(
                  child: SizedBox(
                    height: totalGridHeight,
                    child: Stack(
                      children: [
                        _buildGrid(
                            context,
                            minHour,
                            totalHours,
                            hourHeight,
                            timeColumnWidth,
                            activeDays,
                            dayColumnWidth,
                            headerHeight),
                        ...allSlots.map((slot) {
                          final day = slot['day_of_week'];
                          if (!activeDays.contains(day))
                            return const SizedBox.shrink();

                          final dayIndex = activeDays.indexOf(day);
                          final startMinutes =
                              _timeToMinutes(slot['start_time']);
                          var endMinutes = _timeToMinutes(slot['end_time']);
                          if (endMinutes == 0 && startMinutes > 0)
                            endMinutes = 24 * 60;

                          final durationMinutes = endMinutes - startMinutes;
                          if (durationMinutes <= 0)
                            return const SizedBox.shrink();

                          final topOffset =
                              ((startMinutes - (minHour * 60)) / 60) *
                                  hourHeight;
                          final top = topOffset + headerHeight;
                          final height = (durationMinutes / 60) * hourHeight;
                          final left =
                              timeColumnWidth + (dayIndex * dayColumnWidth);
                          final slotColor = _generateColor(slot['subject_id']);

                          return Positioned(
                            top: top,
                            left: isRTL ? null : left,
                            right: isRTL ? left : null,
                            width: dayColumnWidth,
                            height: height,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: GlassCard(
                                color: slotColor.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                                child: Center(
                                  child: Text(
                                    slot['subject_code'] ?? 'N/A',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
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
}

// ... Rest of the widgets ...
Widget _buildGrid(
    BuildContext context,
    int startHour,
    int totalHours,
    double hourHeight,
    double timeColumnWidth,
    List<String> activeDays,
    double dayColumnWidth,
    double headerHeight) {
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
          height: headerHeight,
          child: Row(children: [
            SizedBox(width: timeColumnWidth),
            ...activeDays.map((day) => SizedBox(
                width: dayColumnWidth,
                child: Center(
                    child: Text(shortDayNames[day] ?? '',
                        style: theme.textTheme.titleSmall))))
          ])),
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: timeColumnWidth,
                child: Column(
                    children: List.generate(
                        totalHours,
                        (index) => SizedBox(
                            height: hourHeight,
                            child: Transform.translate(
                                offset: const Offset(0, -7),
                                child: Text('${startHour + index}:00',
                                    style: theme.textTheme.bodySmall)))))),
            Expanded(
              child: Stack(
                children: [
                  ...List.generate(
                      totalHours + 1,
                      (index) => Positioned(
                          top: index * hourHeight,
                          left: 0,
                          right: 0,
                          child: Container(
                              height: 1,
                              color: theme.dividerColor.withOpacity(0.5)))),
                  ...List.generate(
                      activeDays.length,
                      (index) => Positioned(
                          top: 0,
                          bottom: 0,
                          left: index * dayColumnWidth,
                          child: Container(
                              width: 1,
                              color: theme.dividerColor.withOpacity(0.5)))),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _CourseLegend extends StatelessWidget {
  final ScheduleResult scheduleResult;
  final Color Function(int) generateColor;

  const _CourseLegend(
      {required this.scheduleResult, required this.generateColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('agenda_course_legend'.tr,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppColors.primary)),
            const Divider(),
            ...scheduleResult.scheduledCourses.map((course) {
              final hasLab = course.schedules
                  .any((s) => s['schedule_type'] == 'PRACTICAL');
              final lectureColor = generateColor(course.subject['id']);
              final labColor = lectureColor.withOpacity(0.7);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(course.subject['name'],
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis)),
                    Text('agenda_lecture'.tr, style: theme.textTheme.bodySmall),
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: lectureColor, shape: BoxShape.circle)),
                    if (hasLab) ...[
                      const SizedBox(width: 8),
                      Text('agenda_lab'.tr, style: theme.textTheme.bodySmall),
                      Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: labColor, shape: BoxShape.circle)),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
