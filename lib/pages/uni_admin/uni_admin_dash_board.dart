import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/data/services/auth_services.dart';
import 'package:unicurve/pages/auth/login/login_page.dart';
import 'package:unicurve/pages/uni_admin/majors/views/manage_majors_page.dart';
import 'package:unicurve/pages/uni_admin/providers/admin_university_provider.dart';
import 'package:unicurve/pages/uni_admin/providers/majors_provider.dart';
import 'package:unicurve/pages/uni_admin/select_major_page.dart';
import 'package:unicurve/pages/uni_admin/uni_admin_widgets/navigation_card.dart';

class UniAdminDashboardPage extends ConsumerWidget {
  const UniAdminDashboardPage({super.key});

  Future<void> logout(BuildContext context, WidgetRef ref) async {
    final authService = AuthService();
    try {
      // Clear cached data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all caches
      ref.invalidate(adminUniversityProvider); // Invalidate providers
      ref.invalidate(majorsProvider);

      await authService.signOut();
      await authService.clearCredentials();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = ScaleConfig(context);
    final adminUniversityAsync = ref.watch(adminUniversityProvider);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: CustomAppBar(
        title: adminUniversityAsync.when(
          data: (adminUniversity) =>
              adminUniversity != null ? "${adminUniversity['university_name']} Admin" : "Admin Dashboard",
          loading: () => "Loading...",
          error: (_, __) => "Admin Dashboard",
        ),
        centerTitle: true,
        backgroundColor: AppColors.darkBackground,
        actions: [
          IconButton(
            onPressed: () => logout(context, ref),
            icon: const Icon(Icons.logout, color: AppColors.darkTextPrimary),
          ),
        ],
      ),
      body: adminUniversityAsync.when(
        data: (adminUniversity) {
          if (adminUniversity == null) {
            return Center(
              child: Text(
                'No university data found',
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
                        title: 'Manage Majors',
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
                        title: 'Manage Subjects',
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
                        title: 'Manage Professors',
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
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text(
            'Failed to load university: ${e.toString().replaceFirst('Exception: ', '')}',
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
