// lib/domain/models/subject.dart

// Subject class remains the same...
class Subject {
  final int? id;
  final String code;
  final String name;
  final String? description;
  final int hours;
  final bool isOpen;
  final int? majorId;
  final int level;
  final int? priority;
  final int? type;

  Subject({
    this.id,
    required this.code,
    required this.name,
    this.description,
    required this.hours,
    this.isOpen = false,
    this.majorId,
    required this.level,
    this.priority,
    this.type,
  });

  // fromMap and toMap remain the same...
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'hours': hours,
      'is_open': isOpen,
      'major_id': majorId,
      'level': level,
      'priority': priority,
      'type': type,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      description: map['description'],
      hours: map['hours'],
      isOpen: map['is_open'] ?? false,
      majorId: map['major_id'],
      level: map['level'],
      priority: map['priority'],
      type: map['type'],
    );
  }
}


class SubjectGroup {
  final int id;
  final String groupCode;
  final int subjectId;
  final List<Schedule> schedules;

  SubjectGroup({
    required this.id,
    required this.groupCode,
    required this.subjectId,
    required this.schedules,
  });

  factory SubjectGroup.fromMap(Map<String, dynamic> map) {
    // FIX IS HERE: Changed 'schedules' to 'subject_schedules'
    final schedulesList = (map['subject_schedules'] as List? ?? [])
        .map((scheduleMap) => Schedule.fromMap(scheduleMap))
        .toList();

    return SubjectGroup(
      id: map['id'],
      groupCode: map['group_code'],
      subjectId: map['subject_id'],
      schedules: schedulesList,
    );
  }
}

// Schedule class remains the same...
class Schedule {
  final int id;
  final int groupId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String scheduleType;

  Schedule({
    required this.id,
    required this.groupId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.scheduleType,
  });

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      groupId: map['group_id'],
      dayOfWeek: map['day_of_week'],
      startTime: (map['start_time'] as String).substring(0, 5),
      endTime: (map['end_time'] as String).substring(0, 5),
      scheduleType: map['schedule_type'],
    );
  }
}