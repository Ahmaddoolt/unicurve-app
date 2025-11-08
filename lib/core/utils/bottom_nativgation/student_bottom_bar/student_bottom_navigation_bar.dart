// lib/core/utils/bottom_nativgation/student_bottom_bar/student_bottom_navigation_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/core/utils/bottom_nativgation/screen_index_provider.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/pages/student/best_table_term/views/best_schedule_page.dart';
import 'package:unicurve/pages/student/planning_tools/hub_gpa_page.dart';
import 'package:unicurve/pages/student/student_profile/student_profile_page.dart';
import 'package:unicurve/pages/student/subjects/student_subjects_show.dart';
import 'student_bottom_nav_icon.dart';

class StudentBottomBar extends ConsumerWidget {
  const StudentBottomBar({super.key});

  final Map<StudentTab, Widget> _screens = const {
    StudentTab.subjects: StudentSubjectsPage(),
    StudentTab.schedule: BestSchedulePage(),
    StudentTab.gpa: HubGpaPage(),
    StudentTab.profile: StudentProfilePage(),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final selectedTab = ref.watch(studentTabProvider);
    final notifier = ref.read(studentTabProvider.notifier);

    final List<Map<String, dynamic>> navItems = [
      {'tab': StudentTab.subjects, 'icon': Icons.description_outlined},
      {'tab': StudentTab.schedule, 'icon': Icons.view_week_outlined},
      {'tab': StudentTab.gpa, 'icon': Icons.shape_line_outlined},
      {'tab': StudentTab.profile, 'icon': Icons.person_2_outlined},
    ];

    return Scaffold(
      extendBody: true, // Allows body to go behind the transparent bottom bar
      backgroundColor:
          isDarkMode ? Colors.transparent : theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Layer 1: The Gradient Background (only visible in dark mode)
          if (isDarkMode)
            Container(
              decoration:
                  const BoxDecoration(gradient: AppColors.darkPrimaryGradient),
            ),
          // Layer 2: The actual page content
          _screens[selectedTab]!,
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: isDarkMode ? Colors.transparent : theme.cardColor,
        elevation: isDarkMode ? 0 : 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: navItems.map((item) {
            final StudentTab tab = item['tab'];
            final IconData icon = item['icon'];
            return Expanded(
              child: InkWell(
                onTap: () => notifier.changeTab(tab),
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: StudentBottomNavIcon(
                    icon: icon,
                    isSelected: selectedTab == tab,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
