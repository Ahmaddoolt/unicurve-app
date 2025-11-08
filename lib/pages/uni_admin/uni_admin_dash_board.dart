// lib/pages/uni_admin/uni_admin_dash_board.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/uni_admin/majors/views/manage_majors_page.dart';
import 'package:unicurve/pages/uni_admin/providers/admin_university_provider.dart';
import 'package:unicurve/pages/uni_admin/select_major_page.dart';
import 'package:unicurve/pages/uni_admin/uni_admin_widgets/navigation_card.dart';

class UniAdminDashboardPage extends ConsumerWidget {
  const UniAdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = context.scaleConfig;
    final adminUniversityAsync = ref.watch(adminUniversityProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (isDarkMode) {
      // --- DARK MODE IMPLEMENTATION ---
      return GradientScaffold(
        appBar: CustomAppBar(
          useGradient: false,
          // *** ERROR FIX: Pass the helper widget to `titleWidget` instead of `title` ***
          titleWidget: _buildAppBarTitle(adminUniversityAsync),
        ),
        body: _buildBody(context, ref, scaleConfig, adminUniversityAsync),
      );
    } else {
      // --- LIGHT MODE IMPLEMENTATION ---
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          useGradient: true,

          // *** ERROR FIX: Pass the helper widget to `titleWidget` instead of `title` ***
          titleWidget: _buildAppBarTitle(adminUniversityAsync),
        ),
        body: _buildBody(context, ref, scaleConfig, adminUniversityAsync),
      );
    }
  }

  // Helper widget for the AppBar title to avoid code duplication
  Widget _buildAppBarTitle(
      AsyncValue<Map<String, dynamic>?> adminUniversityAsync) {
    return adminUniversityAsync.when(
      data: (adminUniversity) {
        return Text(
          adminUniversity != null
              ? 'admin_dashboard_title_with_name'.trParams({
                  'uniName': adminUniversity['university_name'],
                })
              : 'admin_dashboard_title_fallback'.tr,
        );
      },
      loading: () => Text('loading_text'.tr),
      error: (_, __) => Text('admin_dashboard_title_fallback'.tr),
    );
  }

  // Helper widget for the body content to avoid code duplication
  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ScaleConfig scaleConfig,
    AsyncValue<Map<String, dynamic>?> adminUniversityAsync,
  ) {
    return adminUniversityAsync.when(
      data: (adminUniversity) {
        if (adminUniversity == null) {
          return Center(
            child: Text(
              'error_no_university_found'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.error,
                fontSize: scaleConfig.scaleText(16),
              ),
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleConfig.scale(24)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildNavigationCard(
                context,
                scaleConfig,
                title: 'admin_manage_majors'.tr,
                icon: Icons.school_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageMajorsPage()),
                  );
                },
              ),
              buildNavigationCard(
                context,
                scaleConfig,
                title: 'admin_manage_subjects'.tr,
                icon: Icons.book_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SelectMajorPage(wPage: 0)),
                  );
                },
              ),
              buildNavigationCard(
                context,
                scaleConfig,
                title: 'admin_manage_professors'.tr,
                icon: Icons.groups_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SelectMajorPage(wPage: 1)),
                  );
                },
              ),
              SizedBox(
                height: 15,
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text(
          'error_failed_to_load_university'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.error,
            fontSize: scaleConfig.scaleText(16),
          ),
        ),
      ),
    );
  }
}
