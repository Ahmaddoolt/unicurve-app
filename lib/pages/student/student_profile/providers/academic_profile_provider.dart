import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/pages/student/best_table_term/providers/schedule_repository.dart';
import 'package:unicurve/pages/student/student_profile/providers/university_cache_service.dart';

class RequirementProgress {
  final String name;
  final int completedHours;
  final int requiredHours;

  RequirementProgress({
    required this.name,
    required this.completedHours,
    required this.requiredHours,
  });
}

class AcademicProfile {
  final Map<String, dynamic>? studentData;
  final String? universityType;
  final List<Map<String, dynamic>> takenSubjects;
  final int completedHours;
  final int totalMajorHours;
  final double cumulativeGpa;
  final double totalHistoricalQualityPoints;
  final int totalHistoricalHours;
  final List<RequirementProgress> requirementsProgress;

  AcademicProfile({
    this.studentData,
    this.universityType,
    required this.takenSubjects,
    required this.completedHours,
    required this.totalMajorHours,
    required this.cumulativeGpa,
    required this.totalHistoricalQualityPoints,
    required this.totalHistoricalHours,
    required this.requirementsProgress,
  });
}

class AcademicProfileNotifier
    extends StateNotifier<AsyncValue<AcademicProfile>> {
  final _supabase = Supabase.instance.client;
  final _cacheService = UniversityCacheService();

  AcademicProfileNotifier() : super(const AsyncLoading()) {
    fetchProfileData();
  }

  double _getGradePoint(int? mark, String? uniType) {
    if (mark == null) return 0.0;
    if (uniType == 'Public') {
      if (mark < 60) return 0.0;
      if (mark >= 98) return 4.0;
      if (mark >= 95) return 3.75;
      if (mark >= 90) return 3.5;
      if (mark >= 85) return 3.25;
      if (mark >= 80) return 3.0;
      if (mark >= 75) return 2.75;
      if (mark >= 70) return 2.5;
      if (mark >= 65) return 2.25;
      if (mark >= 60) return 2.0;
      return 0.0;
    }
    if (mark >= 98) return 4.0;
    if (mark >= 95) return 3.75;
    if (mark >= 90) return 3.5;
    if (mark >= 85) return 3.25;
    if (mark >= 80) return 3.0;
    if (mark >= 75) return 2.75;
    if (mark >= 70) return 2.5;
    if (mark >= 65) return 2.25;
    if (mark >= 60) return 2.0;
    if (mark >= 55) return 1.75;
    if (mark >= 50) return 1.5;
    return 0.0;
  }

  Future<void> fetchProfileData() async {
    state = const AsyncLoading();
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in.');

      final profileData =
          await _supabase
              .from('students')
              .select('*, majors(name), universities(uni_type)')
              .eq('user_id', userId)
              .single();

      final universityData = profileData['universities'];
      final String? uniType = universityData?['uni_type'];

      if (uniType != null) {
        await _cacheService.saveUniversityType(uniType);
      }

      final studentMajorId = profileData['major_id'];
      if (studentMajorId == null) throw Exception("Student major not set.");

      final parallelResults = await Future.wait([
        _supabase
            .from('student_taken_subjects')
            .select('id, status, mark, subjects(id, name, code, hours, type)')
            .eq('student_user_id', userId),
        _supabase
            .from('major_requirements')
            .select('id, requirement_name, required_hours')
            .eq('major_id', studentMajorId),
      ]);

      final takenSubjects = List<Map<String, dynamic>>.from(
        parallelResults[0] as List,
      );
      final requirementsResponse = List<Map<String, dynamic>>.from(
        parallelResults[1] as List,
      );

      int totalMajorHours = requirementsResponse.fold(
        0,
        (sum, req) => sum + (req['required_hours'] as int? ?? 0),
      );

      double historicalPoints = 0;
      int historicalHours = 0;
      int completedHours = 0;
      final Map<int, int> completedHoursPerType = {};

      for (final takenSubject in takenSubjects) {
        final subjectDetails = takenSubject['subjects'];
        if (subjectDetails != null) {
          final int hours = subjectDetails['hours'] ?? 0;
          final int? typeId = subjectDetails['type'];
          final status = takenSubject['status'];

          if (status == 'passed') {
            completedHours += hours;
            if (typeId != null) {
              completedHoursPerType[typeId] =
                  (completedHoursPerType[typeId] ?? 0) + hours;
            }
          }
          if (hours > 0) {
            historicalPoints +=
                (_getGradePoint(takenSubject['mark'], uniType) * hours);
            historicalHours += hours;
          }
        }
      }

      final gpa =
          historicalHours > 0 ? historicalPoints / historicalHours : 0.0;
      final List<RequirementProgress> reqProgressList =
          requirementsResponse.map((req) {
            final reqId = req['id'] as int;
            return RequirementProgress(
              name: req['requirement_name'] ?? 'Unnamed Requirement',
              completedHours: completedHoursPerType[reqId] ?? 0,
              requiredHours: req['required_hours'] ?? 0,
            );
          }).toList();

      final profile = AcademicProfile(
        studentData: profileData,
        universityType: uniType,
        takenSubjects: takenSubjects,
        completedHours: completedHours,
        totalMajorHours: totalMajorHours,
        cumulativeGpa: gpa,
        totalHistoricalQualityPoints: historicalPoints,
        totalHistoricalHours: historicalHours,
        requirementsProgress: reqProgressList,
      );

      state = AsyncData(profile);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteMark(int recordId, WidgetRef ref) async {
    try {
      await _supabase
          .from('student_taken_subjects')
          .delete()
          .eq('id', recordId);
      await fetchProfileData();
      ref.invalidate(scheduleDataCacheProvider);
    } catch (e) {
      throw Exception('Failed to delete mark: $e');
    }
  }
}

final academicProfileProvider =
    StateNotifierProvider<AcademicProfileNotifier, AsyncValue<AcademicProfile>>(
      (ref) {
        return AcademicProfileNotifier();
      },
    );
