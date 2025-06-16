import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/core/utils/bottom_nativgation/screen_index_provider.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/pages/admin_boss_dashboard_page.dart';
import 'package:unicurve/pages/home/home_page.dart';
import 'student_bottom_nav_icon.dart';

class SuperAdminBottomBar extends ConsumerWidget {
  const SuperAdminBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var screens = [
      const HomePage(),
      const HomePage(),
      const HomePage(),
      BossAdminPage(),
    ];

    // final adManager = InterstitialAdManager();
    // adManager.loadAd();

    var screenIndex = ref.watch(adminboosCounterProvider);

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
                  ref.read(adminboosCounterProvider.notifier).setToZero();
                },
                child: SuperAdminBottomNavIcon(
                  icon: Icons.description,
                  isSelected: screenIndex == 0,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(adminboosCounterProvider.notifier).setToOne();
                },
                child: SuperAdminBottomNavIcon(
                  icon: Icons.view_week,
                  isSelected: screenIndex == 1,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(adminboosCounterProvider.notifier).setToTwo();
                },
                child: SuperAdminBottomNavIcon(
                  icon: Icons.shape_line,
                  isSelected: screenIndex == 2,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  ref.read(adminboosCounterProvider.notifier).setToThree();
                },
                child: SuperAdminBottomNavIcon(
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
