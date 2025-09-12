import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/student/student_profile/add_subject_mark_page.dart';
import 'package:unicurve/pages/student/student_profile/providers/academic_profile_provider.dart';

class ProfileHeader extends ConsumerWidget {
  final AcademicProfile profile;
  const ProfileHeader({required this.profile, super.key});

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
        Color? lighterColor = Theme.of(context).cardColor;
        Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
        Color? secondaryTextColor =
            Theme.of(context).textTheme.bodyMedium?.color;

        return StatefulBuilder(
          builder: (context, setState) {
            final inputDecoration = InputDecoration(
              labelStyle: TextStyle(color: secondaryTextColor),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  // ignore: deprecated_member_use
                  color: AppColors.primary.withOpacity(0.5),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.error, width: 2),
              ),
            );

            return AlertDialog(
              backgroundColor: lighterColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                'edit_name_title'.tr,
                style: TextStyle(color: primaryTextColor),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: firstNameController,
                      style: TextStyle(color: primaryTextColor),
                      decoration: inputDecoration.copyWith(
                        labelText: 'first_name_label'.tr,
                      ),
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
                      style: TextStyle(color: primaryTextColor),
                      decoration: inputDecoration.copyWith(
                        labelText: 'last_name_label'.tr,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'cancel'.tr,
                    style: const TextStyle(color: AppColors.accent),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            if (formKey.currentState!.validate()) {
                              setState(() => isLoading = true);
                              try {
                                final userId =
                                    Supabase
                                        .instance
                                        .client
                                        .auth
                                        .currentUser!
                                        .id;
                                await Supabase.instance.client
                                    .from('students')
                                    .update({
                                      'first_name':
                                          firstNameController.text.trim(),
                                      'last_name':
                                          lastNameController.text.trim(),
                                    })
                                    .eq('user_id', userId);

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                                ref.invalidate(academicProfileProvider);
                                showFeedbackSnackbar(
                                  // ignore: use_build_context_synchronously
                                  context,
                                  'name_updated_success'.tr,
                                );
                              } catch (e) {
                                // ignore: use_build_context_synchronously
                                showFeedbackSnackbar(context, 'error_wifi'.tr);
                              } finally {
                                if (context.mounted) {
                                  setState(() => isLoading = false);
                                }
                              }
                            }
                          },
                  child:
                      isLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryTextColor,
                            ),
                          )
                          : Text(
                            'save_button'.tr,
                            style: TextStyle(color: primaryTextColor),
                          ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = context.scaleConfig;
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    final studentData = profile.studentData;
    if (studentData == null) return const SizedBox.shrink();

    final firstName = studentData['first_name'] ?? 'not_available'.tr;
    final lastName = studentData['last_name'] ?? '';
    final majorName =
        studentData['majors']?['name'] ??
        studentData['major_name'] ??
        'not_available'.tr;
    final uniNumber = studentData['uni_number'] ?? 'not_available'.tr;
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? 'no_email'.tr;
    final int remainingHours = profile.totalMajorHours - profile.completedHours;

    return Card(
      color: darkerColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        side: const BorderSide(color: AppColors.primaryDark),
      ),
      child: Padding(
        padding: EdgeInsets.all(scaleConfig.scale(14)),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: scaleConfig.scale(26),
                  backgroundColor: AppColors.primary,
                  child: Text(
                    '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}',
                    style: TextStyle(
                      fontSize: scaleConfig.scaleText(20),
                      color: primaryTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 27,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '$firstName $lastName',
                                      style: TextStyle(
                                        fontSize: scaleConfig.scaleText(17),
                                        fontWeight: FontWeight.bold,
                                        color: primaryTextColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '($majorName)',
                                    style: TextStyle(
                                      fontSize: scaleConfig.scaleText(13),
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.edit,
                                color: primaryTextColor,
                                size: scaleConfig.scale(16),
                              ),
                              onPressed:
                                  () => _showEditNameDialog(
                                    context,
                                    ref,
                                    firstName,
                                    lastName,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: scaleConfig.scaleText(11),
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        "${"uni_number_label".tr} : $uniNumber",
                        style: TextStyle(
                          fontSize: scaleConfig.scaleText(10.5),
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 10, color: lighterColor),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'total_credit_hours'.tr,
                  style: TextStyle(
                    fontSize: scaleConfig.scaleText(13),
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${profile.completedHours} / ${profile.totalMajorHours}',
                  style: TextStyle(
                    fontSize: scaleConfig.scaleText(14),
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value:
                  (profile.totalMajorHours > 0)
                      ? (profile.completedHours / profile.totalMajorHours)
                      : 0.0,
              backgroundColor: lighterColor,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(3),
            ),
            if (remainingHours > 0) ...[
              Divider(
                height: 18,
                color: lighterColor,
                thickness: 1,
                indent: 20,
                endIndent: 20,
              ),
              _GraduationProjection(remainingHours: remainingHours),
            ] else if (profile.totalMajorHours > 0) ...[
              Divider(
                height: 18,
                color: lighterColor,
                thickness: 1,
                indent: 20,
                endIndent: 20,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Row(
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
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: scaleConfig.scaleText(14),
                      ),
                    ),
                  ],
                ),
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
    required ScaleConfig scaleConfig,
    required IconData icon,
    required String title,
    required int terms,
    required String years,
    required BuildContext context,
  }) {
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: scaleConfig.scale(18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: scaleConfig.scaleText(9.5),
              color: secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'terms_and_years'.trParams({
            'terms': terms.toString(),
            'years': years,
          }),
          style: TextStyle(
            fontSize: scaleConfig.scaleText(10.5),
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;

    final normalTerms = (remainingHours / 18.0).ceil();
    final fastTerms = (remainingHours / 15.0).ceil();
    final double normalYears = normalTerms / 2.0;
    final double fastYears = fastTerms / 3.0;
    final String normalYearsString = normalYears.toStringAsFixed(1);
    final String fastYearsString = fastYears.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'graduation_projection_title'.tr,
          style: TextStyle(
            fontSize: scaleConfig.scaleText(15),
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 10),
        _buildProjectionRow(
          scaleConfig: scaleConfig,
          icon: Icons.directions_walk,
          title: 'normal_pace_label'.tr,
          terms: normalTerms,
          years: normalYearsString,
          context: context,
        ),
        const SizedBox(height: 8),
        _buildProjectionRow(
          scaleConfig: scaleConfig,
          icon: Icons.rocket_launch_outlined,
          title: 'fast_pace_label'.tr,
          terms: fastTerms,
          years: fastYearsString,
          context: context,
        ),
      ],
    );
  }
}

class AcademicRecord extends ConsumerWidget {
  final AcademicProfile profile;
  const AcademicRecord({required this.profile, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = context.scaleConfig;
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    final takenSubjects = profile.takenSubjects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 7, left: 7, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'academic_record_title'.tr,
                style: TextStyle(
                  fontSize: scaleConfig.scaleText(19),
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              Text(
                '${'gpa_label'.tr}: ${profile.cumulativeGpa.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: scaleConfig.scaleText(15),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        takenSubjects.isEmpty
            ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'no_marks_added'.tr,
                  style: TextStyle(color: secondaryTextColor),
                ),
              ),
            )
            : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: takenSubjects.length,
              itemBuilder: (context, index) {
                final takenSubject = takenSubjects[index];
                final subject = takenSubject['subjects'] ?? {};
                final mark = takenSubject['mark'];
                final status = takenSubject['status'];

                return Card(
                  color: darkerColor,
                  margin: EdgeInsets.symmetric(vertical: scaleConfig.scale(4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color:
                          status == 'passed'
                              // ignore: deprecated_member_use
                              ? AppColors.primary.withOpacity(0.5)
                              // ignore: deprecated_member_use
                              : AppColors.error.withOpacity(0.5),
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      subject['name'] ?? 'unknown_subject'.tr,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          subject['code'] ?? '---',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "(${subject['hours'] ?? '?'})",
                          style: TextStyle(color: secondaryTextColor),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$mark%',
                          style: TextStyle(
                            color:
                                status == 'passed'
                                    ? AppColors.primary
                                    : AppColors.error,
                            fontSize: scaleConfig.scaleText(16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: secondaryTextColor,
                          ),
                          color: darkerColor,
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final success = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => AddSubjectMarkPage(
                                        isEditMode: true,
                                        takenSubjects: takenSubjects,
                                        universityType: profile.universityType,
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
                                builder:
                                    (context) => AlertDialog(
                                      backgroundColor: lighterColor,
                                      title: Text(
                                        'confirm_deletion_title'.tr,
                                        style: TextStyle(
                                          color: primaryTextColor,
                                        ),
                                      ),
                                      content: Text(
                                        'confirm_deletion_message'.tr,
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: Text(
                                            'cancel'.tr,
                                            style: const TextStyle(
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: Text(
                                            'delete_button'.tr,
                                            style: const TextStyle(
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirm == true) {
                                try {
                                  await ref
                                      .read(academicProfileProvider.notifier)
                                      .deleteMark(takenSubject['id'], ref);
                                  showFeedbackSnackbar(
                                    // ignore: use_build_context_synchronously
                                    context,
                                    'mark_deleted_success'.tr,
                                  );
                                } catch (e) {
                                  showFeedbackSnackbar(
                                    // ignore: use_build_context_synchronously
                                    context,
                                    'error_wifi'.tr,
                                    isError: true,
                                  );
                                }
                              }
                            }
                          },
                          itemBuilder:
                              (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.edit_outlined,
                                        color: AppColors.accent,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'edit_mark_popup'.tr,
                                        style: TextStyle(
                                          color: primaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'delete_popup'.tr,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
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
  Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
  Color? lighterColor = Theme.of(context).cardColor;
  Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
  Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: darkerColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        ),
        title: Text(
          'degree_progress_title'.tr,
          style: TextStyle(
            fontSize: scaleConfig.scaleText(17),
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  profile.requirementsProgress.isEmpty
                      ? [
                        Text(
                          'no_requirement_data'.tr,
                          style: TextStyle(color: secondaryTextColor),
                        ),
                      ]
                      : profile.requirementsProgress.map((progress) {
                        final percentage =
                            (progress.requiredHours > 0)
                                ? (progress.completedHours /
                                    progress.requiredHours)
                                : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      progress.name,
                                      style: TextStyle(
                                        fontSize: scaleConfig.scaleText(14),
                                        color: secondaryTextColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'hours_progress'.trParams({
                                      'completed':
                                          progress.completedHours.toString(),
                                      'required':
                                          progress.requiredHours.toString(),
                                    }),
                                    style: TextStyle(
                                      fontSize: scaleConfig.scaleText(14),
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: percentage.clamp(0.0, 1.0),
                                backgroundColor: lighterColor,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                                minHeight: 17,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'close_button'.tr,
              style: const TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      );
    },
  );
}
