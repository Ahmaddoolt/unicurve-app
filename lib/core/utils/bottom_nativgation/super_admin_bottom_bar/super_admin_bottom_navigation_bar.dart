import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/core/utils/bottom_nativgation/screen_index_provider.dart';
import 'package:unicurve/pages/super_admin/admin_boss_dashboard_page.dart';
import 'package:unicurve/pages/super_admin/super_admin_settings_page.dart';
import 'super_admin_bottom_nav_icon.dart';

class SuperAdminBottomBar extends ConsumerWidget {
  const SuperAdminBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var screens = [const BossAdminPage(), const SuperAdminSettingsPage()];

    var screenIndex = ref.watch(adminboosCounterProvider);

    final double bottomBarHeight = MediaQuery.of(context).size.height * 0.07;

    return Scaffold(
      body: screens[screenIndex],
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).scaffoldBackgroundColor,
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
                  ref.read(adminboosCounterProvider.notifier).setToZero();
                },
                child: SuperAdminBottomNavIcon(
                  icon: Icons.admin_panel_settings,
                  isSelected: screenIndex == 0,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(adminboosCounterProvider.notifier).setToOne();
                },
                child: SuperAdminBottomNavIcon(
                  icon: Icons.settings,
                  isSelected: screenIndex == 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
