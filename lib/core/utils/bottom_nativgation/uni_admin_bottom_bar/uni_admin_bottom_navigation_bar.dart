// lib/core/utils/bottom_nativgation/uni_admin_bottom_bar/uni_admin_bottom_navigation_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/core/utils/bottom_nativgation/screen_index_provider.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/pages/uni_admin/profile_settings_page.dart';
// --- UPDATE: Import the correct page ---
import 'package:unicurve/pages/uni_admin/select_major_page.dart';
import 'package:unicurve/pages/uni_admin/uni_admin_dash_board.dart';
import 'uni_admin_bottom_nav_icon.dart';

class UniAdminBottomBar extends ConsumerWidget {
  const UniAdminBottomBar({super.key});

  // --- THE CRITICAL FIX IS HERE ---
  // The 'subjects' tab no longer points directly to ManageSubjectsPage.
  // It now correctly points to our reusable SelectMajorPage.
  final Map<UniAdminTab, Widget> _screens = const {
    UniAdminTab.dashboard: UniAdminDashboardPage(),
    // When the user taps the subjects tab, they are now correctly
    // taken to the major selection screen first.
    UniAdminTab.subjects: SelectMajorPage(wPage: 2),
    UniAdminTab.profile: ProfileSettingsPage(),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final selectedTab = ref.watch(uniAdminTabProvider);
    final notifier = ref.read(uniAdminTabProvider.notifier);

    final List<Map<String, dynamic>> navItems = [
      {'tab': UniAdminTab.dashboard, 'icon': Icons.dashboard_outlined},
      {'tab': UniAdminTab.subjects, 'icon': Icons.table_chart_outlined},
      {'tab': UniAdminTab.profile, 'icon': Icons.person_2_outlined},
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor:
          isDarkMode ? Colors.transparent : theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (isDarkMode)
            Container(
              decoration:
                  const BoxDecoration(gradient: AppColors.darkPrimaryGradient),
            ),
          // This will now correctly show SelectMajorPage when the subjects tab is active.
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
            final UniAdminTab tab = item['tab'];
            final IconData icon = item['icon'];
            return Expanded(
              child: InkWell(
                onTap: () => notifier.changeTab(tab),
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: UniAdminBottomNavIcon(
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
