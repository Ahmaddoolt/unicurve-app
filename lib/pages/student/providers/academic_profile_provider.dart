// lib/providers/academic_profile_provider.dart

// lib/providers/academic_profile_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// The data model that our provider will hold.
class AcademicProfile {
  final Map<String, dynamic>? studentData;
  final List<Map<String, dynamic>> takenSubjects;
  final int completedHours;
  final int totalMajorHours;
  final double cumulativeGpa;

  final double totalHistoricalQualityPoints;
  final int totalHistoricalHours;

  AcademicProfile({
    this.studentData,
    required this.takenSubjects,
    required this.completedHours,
    required this.totalMajorHours,
    required this.cumulativeGpa,
    required this.totalHistoricalQualityPoints,
    required this.totalHistoricalHours,
  });
}

// The StateNotifier that manages the state.
class AcademicProfileNotifier
    extends StateNotifier<AsyncValue<AcademicProfile>> {
  final _supabase = Supabase.instance.client;

  AcademicProfileNotifier() : super(const AsyncLoading()) {
    fetchProfileData();
  }

  double _getGradePoint(int? mark) {
    if (mark == null) return 0.0;
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
    return 0.0; // Marks below 60 are considered failing for GPA purposes.
  }

  Future<void> fetchProfileData() async {
    state = const AsyncLoading();
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in.');

      final response = await _supabase.rpc(
        'get_student_profile_data',
        params: {'p_user_id': userId},
      );

      final takenSubjects = List<Map<String, dynamic>>.from(
        response['subjects'] ?? [],
      );

      double historicalPoints = 0;
      int historicalHours = 0;
      for (final takenSubject in takenSubjects) {
        if (takenSubject['status'] == 'passed') {
          final subjectDetails = takenSubject['subject'];
          if (subjectDetails != null) {
            final int hours = subjectDetails['hours'] ?? 0;
            if (hours > 0) {
              historicalPoints +=
                  (_getGradePoint(takenSubject['mark']) * hours);
              historicalHours += hours;
            }
          }
        }
      }
      final gpa =
          historicalHours > 0 ? historicalPoints / historicalHours : 0.0;

      final profile = AcademicProfile(
        studentData: response['profile'],
        takenSubjects: takenSubjects,
        completedHours: response['completed_hours'] ?? 0,
        totalMajorHours: response['total_major_hours'] ?? 0,
        cumulativeGpa: gpa,
        totalHistoricalQualityPoints: historicalPoints,
        totalHistoricalHours: historicalHours,
      );

      state = AsyncData(profile);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // --- NEW METHOD TO HANDLE DELETION ---
  Future<void> deleteMark(int recordId) async {
    try {
      await _supabase
          .from('student_taken_subjects')
          .delete()
          .eq('id', recordId);

      // After successful deletion, refresh the profile data.
      await fetchProfileData();
    } catch (e) {
      // Re-throw the error so the UI can catch it and show a message.
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
