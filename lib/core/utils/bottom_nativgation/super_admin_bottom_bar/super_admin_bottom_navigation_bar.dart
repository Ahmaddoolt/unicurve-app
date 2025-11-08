// lib/core/utils/bottom_nativgation/super_admin_bottom_bar/super_admin_bottom_navigation_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/core/utils/bottom_nativgation/screen_index_provider.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/pages/super_admin/admin_boss_dashboard_page.dart';
import 'package:unicurve/pages/super_admin/super_admin_settings_page.dart';
import 'super_admin_bottom_nav_icon.dart';

class SuperAdminBottomBar extends ConsumerWidget {
  const SuperAdminBottomBar({super.key});

  final Map<SuperAdminTab, Widget> _screens = const {
    SuperAdminTab.dashboard: BossAdminPage(),
    SuperAdminTab.settings: SuperAdminSettingsPage(),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final selectedTab = ref.watch(superAdminTabProvider);
    final notifier = ref.read(superAdminTabProvider.notifier);

    final List<Map<String, dynamic>> navItems = [
      {
        'tab': SuperAdminTab.dashboard,
        'icon': Icons.admin_panel_settings_outlined
      },
      {'tab': SuperAdminTab.settings, 'icon': Icons.settings_outlined},
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
            final SuperAdminTab tab = item['tab'];
            final IconData icon = item['icon'];
            return Expanded(
              child: InkWell(
                onTap: () => notifier.changeTab(tab),
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: SuperAdminBottomNavIcon(
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
