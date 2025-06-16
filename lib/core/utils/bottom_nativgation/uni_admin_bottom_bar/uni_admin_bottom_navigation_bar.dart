import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/bottom_nativgation/screen_index_provider.dart';
import 'package:unicurve/pages/home/home_page.dart';
import 'package:unicurve/pages/uni_admin/profile_settings_page.dart';
// Updated import to point to the correct subjects page
import 'package:unicurve/pages/uni_admin/subjects_terms_tables/manage_subjects_times_page.dart';
import 'package:unicurve/pages/uni_admin/uni_admin_dash_board.dart';
import 'uni_admin_bottom_nav_icon.dart';

class UniAdminBottomBar extends ConsumerWidget {
  const UniAdminBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // screens array now directly includes ManageSubjectsPage
    var screens = [
      const UniAdminDashboardPage(),
      const ManageSubjectsPage(), // Navigates directly to the page you made.
      const ProfileSettingsPage(),
    ];

    var screenIndex = ref.watch(uniAdminCounterProvider);

    // Prevent invalid index
    if (screenIndex >= screens.length) {
      ref.read(uniAdminCounterProvider.notifier).setToZero();
      screenIndex = 0;
    }

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
                  ref.read(uniAdminCounterProvider.notifier).setToZero();
                },
                child: UniAdminBottomNavIcon(
                  icon: Icons.note_alt,
                  isSelected: screenIndex == 0,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(uniAdminCounterProvider.notifier).setToOne();
                },
                child: UniAdminBottomNavIcon(
                  icon: Icons.table_chart,
                  isSelected: screenIndex == 1,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // BUG FIX: The third item is at index 2.
                  // Ensure your provider has a setToTwo() method.
                  ref.read(uniAdminCounterProvider.notifier).setToTwo();
                },
                child: UniAdminBottomNavIcon(
                  icon: Icons.person_2,
                  // BUG FIX: The third item is selected when screenIndex is 2.
                  isSelected: screenIndex == 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
