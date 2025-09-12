import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/core/utils/bottom_nativgation/screen_index_provider.dart';
import 'package:unicurve/pages/student/best_table_term/views/best_schedule_page.dart';
import 'package:unicurve/pages/student/planning_tools/hub_gpa_page.dart';
import 'package:unicurve/pages/student/student_profile/student_profile_page.dart';
import 'package:unicurve/pages/student/subjects/student_subjects_show.dart';
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

    var screenIndex = ref.watch(studentCounterProvider);

    final double bottomBarHeight = MediaQuery.of(context).size.height * 0.07;
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      body: screens[screenIndex],
      bottomNavigationBar: BottomAppBar(
        color: darkerColor,
        height: bottomBarHeight,
        shape: const CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.only(top: 7.5, bottom: 7.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            textDirection: TextDirection.ltr,
            children: [
              GestureDetector(
                onTap: () {
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
