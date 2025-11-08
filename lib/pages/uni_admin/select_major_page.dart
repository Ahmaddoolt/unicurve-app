// lib/pages/uni_admin/select_major_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/glass_loading_overlay.dart'; // --- FIX: Import the overlay ---
import 'package:unicurve/core/utils/gradient_icon.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/uni_admin/professors/views/professors_page.dart';
import 'package:unicurve/pages/uni_admin/providers/admin_university_provider.dart';
import 'package:unicurve/pages/uni_admin/providers/majors_provider.dart';
import 'package:unicurve/pages/uni_admin/providers/selected_major_provider.dart';
import 'package:unicurve/pages/uni_admin/subjects/manage_subjects_with_search.dart';
import 'package:unicurve/pages/uni_admin/subjects_terms_tables/manage_subjects_times_page.dart';

class SelectMajorPage extends ConsumerWidget {
  final int wPage;
  const SelectMajorPage({super.key, required this.wPage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBar = CustomAppBar(
      useGradient: !isDarkMode, // Corrected logic for consistency
      title: 'select_major_page_title'.tr,
    );

    final adminUniversityAsync = ref.watch(adminUniversityProvider);

    // This nested provider watch depends on the first one completing.
    // We get the universityId safely before watching the majorsProvider.
    final universityId =
        adminUniversityAsync.valueOrNull?['university_id'] as int?;
    final majorsAsync = ref.watch(majorsProvider(
        universityId ?? -1)); // Use -1 as a placeholder if no ID yet

    final bodyContent = GlassLoadingOverlay(
      isLoading:
          (adminUniversityAsync.isLoading && !adminUniversityAsync.hasValue) ||
              (majorsAsync.isLoading && !majorsAsync.hasValue),
      child: adminUniversityAsync.when(
        data: (adminUniversity) {
          if (adminUniversity == null) {
            return _buildErrorState(
              context,
              scaleConfig,
              'error_no_university_assigned'.tr,
            );
          }
          // Now we can safely use the majorsAsync provider's states
          return majorsAsync.when(
            data: (majors) {
              if (majors.isEmpty) {
                return _buildErrorState(
                  context,
                  scaleConfig,
                  'error_no_majors_found'.tr,
                  icon: Icons.search_off_rounded,
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(majorsProvider(universityId!)),
                color: AppColors.primary,
                child: ListView.builder(
                  padding: EdgeInsets.all(scaleConfig.scale(16)),
                  itemCount: majors.length,
                  itemBuilder: (context, index) {
                    final major = majors[index];
                    return GlassCard(
                      margin: EdgeInsets.only(bottom: scaleConfig.scale(12)),
                      borderRadius: BorderRadius.circular(12.0),
                      child: InkWell(
                        onTap: () => _onMajorTapped(context, ref, major),
                        borderRadius: BorderRadius.circular(12.0),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: scaleConfig.scale(16),
                            vertical: scaleConfig.scale(8),
                          ),
                          leading: Container(
                            width: scaleConfig.scale(44),
                            height: scaleConfig.scale(44),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            child: const Icon(
                              Icons.school_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            major.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: scaleConfig.scaleText(17),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          trailing: GradientIcon(
                            icon: Icons.arrow_forward_ios_rounded,
                            size: scaleConfig.scaleText(16),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () =>
                const SizedBox.shrink(), // Keep UI static while loading
            error: (e, _) => _buildErrorState(
              context,
              scaleConfig,
              'error_wifi'.tr,
              icon: Icons.wifi_off_rounded,
            ),
          );
        },
        loading: () => const SizedBox.shrink(), // Keep UI static while loading
        error: (e, _) => _buildErrorState(
          context,
          scaleConfig,
          'error_wifi'.tr,
          icon: Icons.error_outline_rounded,
        ),
      ),
    );

    if (isDarkMode) {
      return GradientScaffold(
        appBar: appBar,
        body: bodyContent,
      );
    } else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        body: bodyContent,
      );
    }
  }

  void _onMajorTapped(BuildContext context, WidgetRef ref, dynamic major) {
    if (major.id == null) {
      showFeedbackSnackbar(
        context,
        'select_major_error_invalid_id'.tr,
        isError: true,
      );
      return;
    }

    ref.read(selectedMajorIdProvider.notifier).state = major.id;

    Widget? destinationPage;
    switch (wPage) {
      case 0:
        destinationPage = SearchSubjectsPage(majorId: major.id!);
        break;
      case 1:
        destinationPage = ProfessorsPage(majorId: major.id!);
        break;
      case 2:
        destinationPage = const ManageSubjectsPage();
        break;
    }

    if (destinationPage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destinationPage!),
      );
    }
  }

  Widget _buildErrorState(
      BuildContext context, ScaleConfig scaleConfig, String message,
      {IconData? icon}) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(scaleConfig.scale(24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: theme.textTheme.bodyMedium?.color,
                size: scaleConfig.scale(50),
              ),
              SizedBox(height: scaleConfig.scale(16)),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: scaleConfig.scaleText(16),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
