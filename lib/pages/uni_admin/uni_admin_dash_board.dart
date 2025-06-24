import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/uni_admin/majors/views/manage_majors_page.dart';
import 'package:unicurve/pages/uni_admin/providers/admin_university_provider.dart';
import 'package:unicurve/pages/uni_admin/select_major_page.dart';
import 'package:unicurve/pages/uni_admin/uni_admin_widgets/navigation_card.dart';

class UniAdminDashboardPage extends ConsumerWidget {
  const UniAdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = ScaleConfig(context);
    final adminUniversityAsync = ref.watch(adminUniversityProvider);
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: lighterColor,
      appBar: CustomAppBar(
        title: adminUniversityAsync.when(
          data: (adminUniversity) {
            return adminUniversity != null
                ? 'admin_dashboard_title_with_name'.trParams({
                  'uniName': adminUniversity['university_name'],
                })
                : 'admin_dashboard_title_fallback'.tr;
          },
          loading: () => 'loading_text'.tr,
          error: (_, __) => 'admin_dashboard_title_fallback'.tr,
        ),
        centerTitle: true,
        backgroundColor: darkerColor,
        actions: const [],
      ),
      body: adminUniversityAsync.when(
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
            padding: EdgeInsets.all(scaleConfig.scale(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: scaleConfig.scale(8)),
                Expanded(
                  child: ListView(
                    children: [
                      buildNavigationCard(
                        context,
                        scaleConfig,
                        title: 'admin_manage_majors'.tr,
                        icon: Icons.school,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageMajorsPage(),
                            ),
                          );
                        },
                      ),
                      buildNavigationCard(
                        context,
                        scaleConfig,
                        title: 'admin_manage_subjects'.tr,
                        icon: Icons.book,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SelectMajorPage(wPage: 0),
                            ),
                          );
                        },
                      ),
                      buildNavigationCard(
                        context,
                        scaleConfig,
                        title: 'admin_manage_professors'.tr,
                        icon: Icons.local_library,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SelectMajorPage(wPage: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        error:
            (e, _) => Center(
              child: Text(
                'error_failed_to_load_university'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: scaleConfig.scaleText(16),
                ),
              ),
            ),
      ),
    );
  }
}
