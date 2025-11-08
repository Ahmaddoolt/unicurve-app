// lib/pages/student/student_profile/student_profile_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/student/student_profile/add_subject_mark_page.dart';
import 'package:unicurve/pages/student/student_profile/providers/academic_profile_provider.dart';

// --- NEW HELPER WIDGET FOR SKELETON UI ---
class Skeleton extends StatelessWidget {
  final double? height;
  final double? width;
  const Skeleton({super.key, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).splashColor.withOpacity(0.4),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
    );
  }
}

class ProfileHeader extends ConsumerWidget {
  // --- FIX: Profile is now nullable to handle the loading state ---
  final AcademicProfile? profile;
  const ProfileHeader({this.profile, super.key});

  // --- NEW: Skeleton UI for the header ---
  Widget _buildSkeleton(BuildContext context, ScaleConfig scaleConfig) {
    return GlassCard(
      child: Padding(
        padding: EdgeInsets.all(scaleConfig.scale(16)),
        child: Column(
          children: [
            Row(
              children: [
                const Skeleton(height: 52, width: 52),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: scaleConfig.widthPercentage(0.4)),
                      const SizedBox(height: 6),
                      Skeleton(width: scaleConfig.widthPercentage(0.3)),
                      const SizedBox(height: 4),
                      Skeleton(width: scaleConfig.widthPercentage(0.5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Skeleton(width: scaleConfig.widthPercentage(0.3)),
                Skeleton(width: scaleConfig.widthPercentage(0.25)),
              ],
            ),
            const SizedBox(height: 8),
            const Skeleton(height: 10),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentFirstName,
    String currentLastName,
  ) {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController(text: currentFirstName);
    final lastNameController = TextEditingController(text: currentLastName);
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (context) {
        final theme = Theme.of(context);
        final scaleConfig = context.scaleConfig;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              content: GlassCard(
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.all(scaleConfig.scale(24)),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('edit_name_title'.tr,
                            style: theme.textTheme.titleLarge),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: firstNameController,
                          style: theme.textTheme.bodyLarge,
                          decoration:
                              InputDecoration(labelText: 'first_name_label'.tr),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'error_first_name_required'.tr;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: lastNameController,
                          style: theme.textTheme.bodyLarge,
                          decoration:
                              InputDecoration(labelText: 'last_name_label'.tr),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: Text('cancel'.tr),
                            ),
                            const SizedBox(width: 8),
                            CustomButton(
                              onPressed: isLoading
                                  ? () {}
                                  : () async {
                                      if (formKey.currentState!.validate()) {
                                        setState(() => isLoading = true);
                                        try {
                                          final userId = Supabase.instance
                                              .client.auth.currentUser!.id;
                                          await Supabase.instance.client
                                              .from('students')
                                              .update({
                                            'first_name':
                                                firstNameController.text.trim(),
                                            'last_name':
                                                lastNameController.text.trim(),
                                          }).eq('user_id', userId);
                                          if (context.mounted)
                                            Navigator.of(context).pop();
                                          ref.invalidate(
                                              academicProfileProvider);
                                          showFeedbackSnackbar(context,
                                              'name_updated_success'.tr);
                                        } catch (e) {
                                          showFeedbackSnackbar(
                                              context, 'error_wifi'.tr,
                                              isError: true);
                                        } finally {
                                          if (context.mounted)
                                            setState(() => isLoading = false);
                                        }
                                      }
                                    },
                              text: 'save_button'.tr,
                              gradient: isLoading
                                  ? AppColors.disabledGradient
                                  : AppColors.primaryGradient,
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);

    // --- FIX: Check if profile data is null and show skeleton ---
    if (profile == null) {
      return _buildSkeleton(context, scaleConfig);
    }

    final studentData = profile!.studentData;
    if (studentData == null) return const SizedBox.shrink();

    final firstName = studentData['first_name'] ?? 'not_available'.tr;
    final lastName = studentData['last_name'] ?? '';
    final majorName = studentData['majors']?['name'] ??
        studentData['major_name'] ??
        'not_available'.tr;
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? 'no_email'.tr;
    final int remainingHours = profile!.totalMajorHours - profile!.completedHours;

    return GlassCard(
      child: Padding(
        padding: EdgeInsets.all(scaleConfig.scale(16)),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: scaleConfig.scale(52),
                  height: scaleConfig.scale(52),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Center(
                    child: Text(
                      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: scaleConfig.scaleText(22),
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              '$firstName $lastName',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: scaleConfig.scaleText(18)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.edit_outlined,
                                color: theme.textTheme.bodyMedium?.color,
                                size: scaleConfig.scale(18),
                              ),
                              onPressed: () => _showEditNameDialog(
                                context,
                                ref,
                                firstName,
                                lastName,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0),
                        child: Text(
                          majorName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(email, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('total_credit_hours'.tr,
                    style: theme.textTheme.bodyMedium),
                Text(
                  '${profile!.completedHours} / ${profile!.totalMajorHours}',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (profile!.totalMajorHours > 0)
                    ? (profile!.completedHours / profile!.totalMajorHours)
                    : 0.0,
                backgroundColor:
                    theme.colorScheme.surfaceVariant.withOpacity(0.5),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 10,
              ),
            ),
            if (remainingHours > 0) ...[
              Divider(height: 20, color: theme.dividerColor),
              _GraduationProjection(remainingHours: remainingHours),
            ] else if (profile!.totalMajorHours > 0) ...[
              Divider(height: 20, color: theme.dividerColor),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.celebration_rounded,
                    color: AppColors.primary,
                    size: scaleConfig.scale(20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'plan_completed_congrats'.tr,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GraduationProjection extends StatelessWidget {
  final int remainingHours;
  const _GraduationProjection({required this.remainingHours});

  Widget _buildProjectionRow({
    required BuildContext context,
    required ScaleConfig scaleConfig,
    required IconData icon,
    required String title,
    required int terms,
    required String years,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: scaleConfig.scale(18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontSize: scaleConfig.scaleText(13)),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'terms_and_years'
              .trParams({'terms': terms.toString(), 'years': years}),
          style:
              theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    final normalTerms = (remainingHours / 18.0).ceil();
    final fastTerms =
        (remainingHours / 21.0).ceil(); // Assuming fast pace is more hours
    final double normalYears = normalTerms / 2.0;
    final double fastYears = fastTerms / 3.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'graduation_projection_title'.tr,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _buildProjectionRow(
          context: context,
          scaleConfig: scaleConfig,
          icon: Icons.directions_walk,
          title: 'normal_pace_label'.tr,
          terms: normalTerms,
          years: normalYears.toStringAsFixed(1),
        ),
        const SizedBox(height: 8),
        _buildProjectionRow(
          context: context,
          scaleConfig: scaleConfig,
          icon: Icons.rocket_launch_outlined,
          title: 'fast_pace_label'.tr,
          terms: fastTerms,
          years: fastYears.toStringAsFixed(1),
        ),
      ],
    );
  }
}

class AcademicRecord extends ConsumerWidget {
  // --- FIX: Profile is now nullable to handle the loading state ---
  final AcademicProfile? profile;
  const AcademicRecord({this.profile, super.key});

  // --- NEW: Skeleton UI for the academic record list ---
  Widget _buildSkeleton(BuildContext context, ScaleConfig scaleConfig) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(right: 8, left: 8, bottom: 15, top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Skeleton(width: scaleConfig.widthPercentage(0.4)),
              Skeleton(width: scaleConfig.widthPercentage(0.25)),
            ],
          ),
        ),
        // Simulate a few list items
        for (int i = 0; i < 3; i++)
          GlassCard(
            margin: EdgeInsets.symmetric(vertical: scaleConfig.scale(4)),
            child: ListTile(
              leading: const Skeleton(height: 40, width: 40),
              title: Skeleton(width: scaleConfig.widthPercentage(0.5)),
              subtitle: Skeleton(width: scaleConfig.widthPercentage(0.3)),
              trailing: const Skeleton(height: 24, width: 50),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);

    // --- FIX: Check if profile data is null and show skeleton ---
    if (profile == null) {
      return _buildSkeleton(context, scaleConfig);
    }

    final takenSubjects = profile!.takenSubjects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(right: 8, left: 8, bottom: 15, top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'academic_record_title'.tr,
                style: theme.textTheme.titleLarge,
              ),
              Text(
                '${'gpa_label'.tr}: ${profile!.cumulativeGpa.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
        takenSubjects.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('no_marks_added'.tr,
                      style: theme.textTheme.bodyMedium),
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: takenSubjects.length,
                itemBuilder: (context, index) {
                  final takenSubject = takenSubjects[index];
                  final subject = takenSubject['subjects'] ?? {};
                  final mark = takenSubject['mark'];
                  final status = takenSubject['status'];

                  return GlassCard(
                    margin:
                        EdgeInsets.symmetric(vertical: scaleConfig.scale(4)),
                    child: ListTile(
                      title: Text(
                        subject['name'] ?? 'unknown_subject'.tr,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${subject['code'] ?? '---'} (${'hours_label'.trParams({
                              'hours': subject['hours']?.toString() ?? '?'
                            })})',
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$mark%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: status == 'passed'
                                  ? AppColors.primary
                                  : AppColors.error,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert,
                                color: theme.textTheme.bodyMedium?.color),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final success = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddSubjectMarkPage(
                                      isEditMode: true,
                                      takenSubjects: takenSubjects,
                                      universityType: profile!.universityType,
                                      recordId: takenSubject['id'],
                                      initialSubjectId: subject['id'],
                                      initialSubjectName: subject['name'],
                                      initialMark: mark,
                                    ),
                                  ),
                                );
                                if (success == true) {
                                  ref.invalidate(academicProfileProvider);
                                }
                              } else if (value == 'delete') {
                                final bool? confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    contentPadding: EdgeInsets.zero,
                                    content: GlassCard(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            24, 24, 24, 8),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('confirm_deletion_title'.tr,
                                                style:
                                                    theme.textTheme.titleLarge),
                                            const SizedBox(height: 16),
                                            Text('confirm_deletion_message'.tr,
                                                style:
                                                    theme.textTheme.bodyMedium),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: Text('cancel'.tr),
                                                ),
                                                CustomButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  text: 'delete_button'.tr,
                                                  backgroundColor:
                                                      AppColors.error,
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    await ref
                                        .read(academicProfileProvider.notifier)
                                        .deleteMark(takenSubject['id'], ref);
                                    showFeedbackSnackbar(
                                        context, 'mark_deleted_success'.tr);
                                  } catch (e) {
                                    showFeedbackSnackbar(
                                        context, 'error_wifi'.tr,
                                        isError: true);
                                  }
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit_outlined,
                                        color: AppColors.accent),
                                    const SizedBox(width: 8),
                                    Text('edit_mark_popup'.tr),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete_outline,
                                        color: AppColors.error),
                                    const SizedBox(width: 8),
                                    Text('delete_popup'.tr,
                                        style: const TextStyle(
                                            color: AppColors.error)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}

void showRequirementsDialog(
  BuildContext context,
  ScaleConfig scaleConfig,
  AcademicProfile profile,
) {
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: GlassCard(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(scaleConfig.scale(24)),
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('degree_progress_title'.tr,
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 24),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: profile.requirementsProgress.isEmpty
                            ? [
                                Text('no_requirement_data'.tr,
                                    style: theme.textTheme.bodyMedium)
                              ]
                            : profile.requirementsProgress.map((progress) {
                                final percentage = (progress.requiredHours > 0)
                                    ? (progress.completedHours /
                                        progress.requiredHours)
                                    : 0.0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              progress.name,
                                              style: theme.textTheme.bodyMedium,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'hours_progress'.trParams({
                                              'completed': progress
                                                  .completedHours
                                                  .toString(),
                                              'required': progress.requiredHours
                                                  .toString(),
                                            }),
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value: percentage.clamp(0.0, 1.0),
                                          backgroundColor:
                                              theme.colorScheme.surfaceVariant,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                  Color>(AppColors.primary),
                                          minHeight: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('close_button'.tr),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}