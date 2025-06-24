import 'package:flutter/material.dart';

class ScheduledCourse {
  final Map<String, dynamic> subject;
  final Map<String, dynamic> group;
  final List<Map<String, dynamic>> schedules;

  ScheduledCourse({
    required this.subject,
    required this.group,
    required this.schedules,
  });
}

class ScheduleResult {
  final List<ScheduledCourse> scheduledCourses;
  final int totalHours;
  final List<TimeSlot> timeSlots;
  final int uniqueDays;

  ScheduleResult({
    required this.scheduledCourses,
    required this.totalHours,
    required this.timeSlots,
  }) : uniqueDays = timeSlots.map((ts) => ts.dayOfWeek).toSet().length;

  factory ScheduleResult.empty() {
    return ScheduleResult(scheduledCourses: [], totalHours: 0, timeSlots: []);
  }
}

class TimeSlot {
  final String dayOfWeek;
  final TimeOfDay start;
  final TimeOfDay end;

  TimeSlot(this.dayOfWeek, String startTime, String endTime)
    : start = TimeOfDay(
        hour: int.parse(startTime.split(':')[0]),
        minute: int.parse(startTime.split(':')[1]),
      ),
      end = TimeOfDay(
        hour: int.parse(endTime.split(':')[0]),
        minute: int.parse(endTime.split(':')[1]),
      );

  bool conflictsWith(TimeSlot other) {
    if (dayOfWeek != other.dayOfWeek) {
      return false;
    }
    final aStartsBeforeBEnds =
        (start.hour < other.end.hour) ||
        (start.hour == other.end.hour && start.minute < other.end.minute);
    final aEndsAfterBStarts =
        (end.hour > other.start.hour) ||
        (end.hour == other.start.hour && end.minute > other.start.minute);
    return aStartsBeforeBEnds && aEndsAfterBStarts;
  }
}

class AvailableSubject {
  final Map<String, dynamic> subject;
  final List<Map<String, dynamic>> groups;
  final int priority;
  final String requirementName;
  final bool isBanned;

  AvailableSubject({
    required this.subject,
    required this.groups,
    required this.priority,
    required this.requirementName,
    this.isBanned = false,
  });
}
