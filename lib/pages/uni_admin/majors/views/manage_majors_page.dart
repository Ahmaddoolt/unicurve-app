// lib/pages/uni_admin/majors/views/manage_majors_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_floadt_action_button.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/glass_loading_overlay.dart'; // --- FIX: Import the overlay ---
import 'package:unicurve/core/utils/gradient_icon.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/major.dart';
import 'package:unicurve/pages/uni_admin/majors/views/add_major_dialog.dart';
import 'package:unicurve/pages/uni_admin/majors/views/edit_major_dialog.dart';
import 'package:unicurve/pages/uni_admin/majors/views/manage_major_requirements_page.dart';
import 'package:unicurve/pages/uni_admin/providers/admin_university_provider.dart';
import 'package:unicurve/pages/uni_admin/providers/majors_provider.dart';

class ManageMajorsPage extends ConsumerWidget {
  const ManageMajorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = context.scaleConfig;
    final adminUniversityAsync = ref.watch(adminUniversityProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBar = CustomAppBar(
      title: 'manage_majors_page_title'.tr,
      centerTitle: true,
      useGradient: !isDarkMode,
    );

    final universityId =
        adminUniversityAsync.valueOrNull?['university_id'] as int?;
    final majorsAsync = ref.watch(majorsProvider(universityId ?? -1));

    final bodyContent = GlassLoadingOverlay(
      isLoading:
          (adminUniversityAsync.isLoading && !adminUniversityAsync.hasValue) ||
              (majorsAsync.isLoading && !majorsAsync.hasValue),
      child: adminUniversityAsync.when(
        data: (adminUniversity) {
          if (adminUniversity == null) {
            return _buildErrorState(context, 'error_no_university_assigned'.tr);
          }
          return majorsAsync.when(
            data: (majors) => majors.isEmpty
                ? _buildErrorState(context, 'majors_empty_list_prompt'.tr)
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async =>
                        ref.invalidate(majorsProvider(universityId!)),
                    child: ListView.builder(
                      padding: EdgeInsets.all(scaleConfig.scale(16)),
                      itemCount: majors.length,
                      itemBuilder: (context, index) {
                        final major = majors[index];
                        return GlassCard(
                          margin:
                              EdgeInsets.only(bottom: scaleConfig.scale(12)),
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
                              child: const Icon(Icons.school_outlined,
                                  color: Colors.white, size: 22),
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: GradientIcon(
                                    icon: Icons.rule_folder_outlined,
                                    size: scaleConfig.scale(22),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ManageMajorRequirementsPage(
                                                major: major),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: scaleConfig.scale(22),
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                  onPressed: () =>
                                      _showEditDialog(context, major, ref),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (e, _) => _buildErrorState(
                context, 'error_generic'.trParams({'error': e.toString()})),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (e, _) => _buildErrorState(
            context, 'error_generic'.trParams({'error': e.toString()})),
      ),
    );

    if (isDarkMode) {
      return GradientScaffold(
        appBar: appBar,
        body: bodyContent,
        floatingActionButton: _buildFAB(context, ref, adminUniversityAsync),
      );
    } else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        body: bodyContent,
        floatingActionButton: _buildFAB(context, ref, adminUniversityAsync),
      );
    }
  }

  Widget _buildFAB(BuildContext context, WidgetRef ref,
      AsyncValue<Map<String, dynamic>?> adminUniversityAsync) {
    return CustomFAB(
      onPressed: () {
        if (adminUniversityAsync.hasValue &&
            adminUniversityAsync.value != null) {
          showDialog(
            context: context,
            builder: (context) => AddMajorDialog(
              adminUniversity: adminUniversityAsync.value,
              onSuccess: () {
                ref.invalidate(majorsProvider(
                    adminUniversityAsync.value!['university_id']));
              },
            ),
          );
        }
      },
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    Major major,
    WidgetRef ref,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => EditMajorDialog(
        major: major,
        onSuccess: () {
          ref.invalidate(majorsProvider(major.universityId));
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style:
              TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 16),
        ),
      ),
    );
  }
}
