import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/core/utils/bottom_nativgation/screen_index_provider.dart';
import 'package:unicurve/pages/uni_admin/profile_settings_page.dart';
import 'package:unicurve/pages/uni_admin/subjects_terms_tables/manage_subjects_times_page.dart';
import 'package:unicurve/pages/uni_admin/uni_admin_dash_board.dart';
import 'uni_admin_bottom_nav_icon.dart';

class UniAdminBottomBar extends ConsumerWidget {
  const UniAdminBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var screens = [
      const UniAdminDashboardPage(),
      const ManageSubjectsPage(),
      const ProfileSettingsPage(),
    ];

    var screenIndex = ref.watch(uniAdminCounterProvider);

    if (screenIndex >= screens.length) {
      ref.read(uniAdminCounterProvider.notifier).setToZero();
      screenIndex = 0;
    }

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
                  ref.read(uniAdminCounterProvider.notifier).setToTwo();
                },
                child: UniAdminBottomNavIcon(
                  icon: Icons.person_2,
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
