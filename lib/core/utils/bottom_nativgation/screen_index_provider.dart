// lib/core/utils/bottom_nativgation/screen_index_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- STUDENT NAVIGATION ---
enum StudentTab { subjects, schedule, gpa, profile }

class StudentTabNotifier extends StateNotifier<StudentTab> {
  StudentTabNotifier() : super(StudentTab.subjects);
  void changeTab(StudentTab tab) {
    state = tab;
  }
}

final studentTabProvider =
    StateNotifierProvider<StudentTabNotifier, StudentTab>((ref) {
  return StudentTabNotifier();
});

// --- NEW PROVIDER TO CONTROL FAB VISIBILITY ---
final isFabVisibleOnProfileProvider = Provider<bool>((ref) {
  // The FAB should only be visible when the profile tab is selected.
  final currentTab = ref.watch(studentTabProvider);
  return currentTab == StudentTab.profile;
});

// --- UNIVERSITY ADMIN NAVIGATION ---
enum UniAdminTab { dashboard, subjects, profile }

class UniAdminTabNotifier extends StateNotifier<UniAdminTab> {
  UniAdminTabNotifier() : super(UniAdminTab.dashboard);
  void changeTab(UniAdminTab tab) {
    state = tab;
  }
}

final uniAdminTabProvider =
    StateNotifierProvider<UniAdminTabNotifier, UniAdminTab>((ref) {
  return UniAdminTabNotifier();
});

// --- SUPER ADMIN NAVIGATION ---
enum SuperAdminTab { dashboard, settings }

class SuperAdminTabNotifier extends StateNotifier<SuperAdminTab> {
  SuperAdminTabNotifier() : super(SuperAdminTab.dashboard);
  void changeTab(SuperAdminTab tab) {
    state = tab;
  }
}

final superAdminTabProvider =
    StateNotifierProvider<SuperAdminTabNotifier, SuperAdminTab>((ref) {
  return SuperAdminTabNotifier();
});
