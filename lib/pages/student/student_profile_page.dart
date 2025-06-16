import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/student/add_subject_mark_page.dart';
import 'package:unicurve/pages/student/providers/academic_profile_provider.dart';
import 'package:unicurve/pages/student/student_setting-page.dart';

class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

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
        return StatefulBuilder(
          builder: (context, setState) {
            final inputDecoration = InputDecoration(
              labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
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
              backgroundColor: AppColors.darkSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                'Edit Name',
                style: TextStyle(color: AppColors.darkTextPrimary),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: firstNameController,
                      style: const TextStyle(color: AppColors.darkTextPrimary),
                      decoration: inputDecoration.copyWith(
                        labelText: 'First Name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'First name is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: lastNameController,
                      style: const TextStyle(color: AppColors.darkTextPrimary),
                      decoration: inputDecoration.copyWith(
                        labelText: 'Last Name',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.accent),
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

                                if (context.mounted)
                                  Navigator.of(context).pop();
                                ref.invalidate(academicProfileProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Name updated successfully!'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to update name: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              } finally {
                                if (context.mounted) {
                                  setState(() => isLoading = false);
                                }
                              }
                            }
                          },
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'Save',
                            style: TextStyle(color: Colors.white),
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
    final profileAsync = ref.watch(academicProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.darkBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined , color: AppColors.accent,),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentSettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        error:
            (error, stack) => Center(
              child: Text(
                'Error: $error',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
        data: (profile) {
          return RefreshIndicator(
            onRefresh:
                () =>
                    ref
                        .read(academicProfileProvider.notifier)
                        .fetchProfileData(),
            color: AppColors.primary,
            backgroundColor: AppColors.darkBackground,
            child: ListView(
              padding: EdgeInsets.all(scaleConfig.scale(12)),
              children: [
                _buildProfileHeader(context, ref, scaleConfig, profile),
                SizedBox(height: scaleConfig.scale(20)),
                _buildAcademicRecord(context, scaleConfig, profile, ref),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addMarkFab',
        onPressed: () async {
          final success = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AddSubjectMarkPage(
                    takenSubjects: profileAsync.value!.takenSubjects,
                  ),
            ),
          );
          if (success == true) {
            ref.invalidate(academicProfileProvider);
          }
        },
        label: const Text('Add Mark'),
        icon: const Icon(Icons.add_chart),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    ScaleConfig scaleConfig,
    AcademicProfile profile,
  ) {
    final studentData = profile.studentData;
    if (studentData == null) return const SizedBox.shrink();

    final firstName = studentData['first_name'] ?? 'N/A';
    final lastName = studentData['last_name'] ?? '';
    final majorName = studentData['major_name'] ?? 'N/A';
    final uniNumber = studentData['uni_number'] ?? 'N/A';
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? 'No email';

    final int remainingHours = profile.totalMajorHours - profile.completedHours;

    return Card(
      color: AppColors.darkBackground,
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
                      color: Colors.white,
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
                            Row(
                              children: [
                                Text(
                                  '$firstName $lastName',
                                  style: TextStyle(
                                    fontSize: scaleConfig.scaleText(17),
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkTextPrimary,
                                    // --- THE DEFINITIVE FIX: TIGHTENS THE LINE HEIGHT ---
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '($majorName)',
                                  style: TextStyle(
                                    fontSize: scaleConfig.scaleText(13),
                                    color: AppColors.primary,
                                    // --- THE DEFINITIVE FIX: TIGHTENS THE LINE HEIGHT ---
                                  ),
                                ),
                              ],
                            ),

                            IconButton(
                              padding: EdgeInsets.zero,

                              icon: Icon(
                                Icons.edit,
                                color: AppColors.darkTextSecondary,
                                size: scaleConfig.scale(13),
                              ),
                              onPressed: () {
                                _showEditNameDialog(
                                  context,
                                  ref,
                                  firstName,
                                  lastName,
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      Text(
                        email,
                        style: TextStyle(
                          fontSize: scaleConfig.scaleText(11),
                          color: AppColors.darkTextSecondary,
                          // --- THE DEFINITIVE FIX: TIGHTENS THE LINE HEIGHT ---
                        ),
                      ),
                      Text(
                        "UniNumber : $uniNumber",
                        style: TextStyle(
                          fontSize: scaleConfig.scaleText(10.5),
                          color: AppColors.darkTextSecondary,

                          // --- THE DEFINITIVE FIX: TIGHTENS THE LINE HEIGHT ---
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 10, color: AppColors.darkSurface),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Credit Hours',
                  style: TextStyle(
                    fontSize: scaleConfig.scaleText(13),
                    color: AppColors.darkTextSecondary,
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
              backgroundColor: AppColors.darkSurface,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(3),
            ),
            if (remainingHours > 0) ...[
              const Divider(
                height: 18,
                color: AppColors.darkSurface,
                thickness: 1,
                indent: 20,
                endIndent: 20,
              ),
              _buildGraduationProjection(context, scaleConfig, remainingHours),
            ] else if (profile.totalMajorHours > 0) ...[
              const Divider(
                height: 18,
                color: AppColors.darkSurface,
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
                      'Congratulations! Plan Completed!',
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

  Widget _buildGraduationProjection(
    BuildContext context,
    ScaleConfig scaleConfig,
    int remainingHours,
  ) {
    final normalTerms = (remainingHours / 18.0).ceil();
    final normalYears = (normalTerms / 2.0).toStringAsFixed(1);

    final fastTerms = (remainingHours / 15.0).ceil();
    final fastYears = (fastTerms / 3.0).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Graduation Projection (تقريباً)',
          style: TextStyle(
            fontSize: scaleConfig.scaleText(15),
            fontWeight: FontWeight.bold,
            color: AppColors.darkTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _buildProjectionRow(
          scaleConfig: scaleConfig,
          icon: Icons.directions_walk,
          title: 'Normal Pace:',
          terms: normalTerms,
          years: normalYears,
        ),
        const SizedBox(height: 8),
        _buildProjectionRow(
          scaleConfig: scaleConfig,
          icon: Icons.rocket_launch_outlined,
          title: 'Fast Pace (w/ summers):',
          terms: fastTerms,
          years: fastYears,
        ),
      ],
    );
  }

  Widget _buildProjectionRow({
    required ScaleConfig scaleConfig,
    required IconData icon,
    required String title,
    required int terms,
    required String years,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: scaleConfig.scale(18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: scaleConfig.scaleText(13),
              color: AppColors.darkTextSecondary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$terms terms (~$years years)',
          style: TextStyle(
            fontSize: scaleConfig.scaleText(13),
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicRecord(
    BuildContext context,
    ScaleConfig scaleConfig,
    AcademicProfile profile,
    WidgetRef ref,
  ) {
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
                'Academic Record',
                style: TextStyle(
                  fontSize: scaleConfig.scaleText(19),
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              Text(
                'GPA: ${profile.cumulativeGpa.toStringAsFixed(2)}',
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
            ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No marks added yet.',
                  style: TextStyle(color: AppColors.darkTextSecondary),
                ),
              ),
            )
            : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: takenSubjects.length,
              itemBuilder: (context, index) {
                final takenSubject = takenSubjects[index];
                final subject = takenSubject['subject'] ?? {};
                final mark = takenSubject['mark'];
                final status = takenSubject['status'];

                return Card(
                  color: AppColors.darkBackground,
                  margin: EdgeInsets.symmetric(vertical: scaleConfig.scale(4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color:
                          status == 'passed'
                              ? AppColors.primary.withOpacity(0.5)
                              : AppColors.error.withOpacity(0.5),
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      subject['name'] ?? 'Unknown Subject',
                      style: const TextStyle(
                        color: AppColors.darkTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          subject['code'] ?? '---',
                          style: const TextStyle(
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          "(${subject['hours']})",
                          style: const TextStyle(
                            color: AppColors.darkTextSecondary,
                          ),
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
                          icon: const Icon(
                            Icons.more_vert,
                            color: AppColors.darkTextSecondary,
                          ),
                          color: AppColors.darkBackground,
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final success = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => AddSubjectMarkPage(
                                        isEditMode: true,
                                        takenSubjects: takenSubjects,
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
                                      backgroundColor: AppColors.darkSurface,
                                      title: const Text(
                                        'Confirm Deletion',
                                        style: TextStyle(
                                          color: AppColors.darkTextPrimary,
                                        ),
                                      ),
                                      content: const Text(
                                        'Are you sure you want to delete this mark?',
                                        style: TextStyle(
                                          color: AppColors.darkTextSecondary,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(
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
                                      .deleteMark(takenSubject['id']);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Mark deleted successfully',
                                      ),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text(
                                    'Edit Mark',
                                    style: TextStyle(
                                      color: AppColors.darkTextPrimary,
                                    ),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.error),
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
