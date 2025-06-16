import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/core/utils/bottom_nativgation/screen_index_provider.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/pages/admin_boss_dashboard_page.dart';
import 'package:unicurve/pages/home/home_page.dart';
import 'package:unicurve/pages/student/best_schedule_page.dart';
import 'package:unicurve/pages/student/hub_gpa_page.dart';
import 'package:unicurve/pages/student/student_profile_page.dart';
import 'package:unicurve/pages/student/student_subjects_show.dart';
import 'package:unicurve/pages/student/term_gpa_calculator_page.dart';
import 'student_bottom_nav_icon.dart';

class StudentBottomBar extends ConsumerWidget {
  const StudentBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var screens = [
      const StudentSubjectsPage(),
      const BestSchedulePage(),
      const HubGpaPage(),
      const StudentProfilePage(),
    ];

    // final adManager = InterstitialAdManager();
    // adManager.loadAd();

    var screenIndex = ref.watch(studentCounterProvider);

    final double bottomBarHeight = MediaQuery.of(context).size.height * 0.07;

    return Scaffold(
      body: screens[screenIndex],
      bottomNavigationBar: BottomAppBar(
        color: AppColors.darkBackground,
        height: bottomBarHeight,
        shape: const CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.only(top: 7.5, bottom: 7.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  // ref.read(audioPlayerProvider).playTapSound();
                  ref.read(studentCounterProvider.notifier).setToZero();
                },
                child: StudentBottomNavIcon(
                  icon: Icons.description,
                  isSelected: screenIndex == 0,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(studentCounterProvider.notifier).setToOne();
                },
                child: StudentBottomNavIcon(
                  icon: Icons.view_week,
                  isSelected: screenIndex == 1,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(studentCounterProvider.notifier).setToTwo();
                },
                child: StudentBottomNavIcon(
                  icon: Icons.shape_line,
                  isSelected: screenIndex == 2,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  ref.read(studentCounterProvider.notifier).setToThree();
                },
                child: StudentBottomNavIcon(
                  icon: Icons.person_2,
                  isSelected: screenIndex == 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
