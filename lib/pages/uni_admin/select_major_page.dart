import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
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
    final scaleConfig = ScaleConfig(context);
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: lighterColor,
      appBar: AppBar(
        backgroundColor: darkerColor,
        centerTitle: true,
        title: Text(
          'select_major_page_title'.tr,
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: scaleConfig.scaleText(20),
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final adminUniversityAsync = ref.watch(adminUniversityProvider);

          return adminUniversityAsync.when(
            data: (adminUniversity) {
              if (adminUniversity == null) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(scaleConfig.scale(16)),
                    child: Text(
                      'error_no_university_assigned'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: scaleConfig.scaleText(16),
                      ),
                    ),
                  ),
                );
              }

              final universityId = adminUniversity['university_id'] as int;
              final majorsAsync = ref.watch(majorsProvider(universityId));

              return Stack(
                children: [
                  majorsAsync.when(
                    data:
                        (majors) =>
                            majors.isEmpty
                                ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                      scaleConfig.scale(16),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.info,
                                          color: secondaryTextColor,
                                          size: scaleConfig.scale(40),
                                        ),
                                        SizedBox(height: scaleConfig.scale(16)),
                                        Text(
                                          'error_no_majors_found'.tr,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: secondaryTextColor,
                                            fontSize: scaleConfig.scaleText(16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                : RefreshIndicator(
                                  onRefresh: () async {
                                    ref.invalidate(
                                      majorsProvider(universityId),
                                    );
                                  },
                                  child: ListView.builder(
                                    padding: EdgeInsets.all(
                                      scaleConfig.scale(16),
                                    ),
                                    itemCount: majors.length,
                                    itemBuilder: (context, index) {
                                      final major = majors[index];
                                      return AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        margin: EdgeInsets.symmetric(
                                          vertical: scaleConfig.scale(6),
                                        ),
                                        child: Card(
                                          elevation: 2,
                                          color: darkerColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              scaleConfig.scale(8),
                                            ),
                                            side: const BorderSide(
                                              color: AppColors.primary,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: scaleConfig.scale(
                                                    16,
                                                  ),
                                                  vertical: scaleConfig.scale(
                                                    12,
                                                  ),
                                                ),
                                            leading: CircleAvatar(
                                              radius: scaleConfig.scale(20),
                                              backgroundColor: lighterColor,
                                              child: Icon(
                                                Icons.school,
                                                color: AppColors.primary,
                                                size: scaleConfig.scale(20),
                                              ),
                                            ),
                                            title: Text(
                                              major.name,
                                              style: TextStyle(
                                                color: primaryTextColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: scaleConfig.scaleText(
                                                  16,
                                                ),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            trailing: Icon(
                                              Icons.arrow_forward_ios,
                                              color: AppColors.accent,
                                              size: scaleConfig.scaleText(16),
                                            ),
                                            onTap: () {
                                              if (major.id == null) {
                                                showFeedbackSnackbar(
                                                  context,
                                                  'select_major_error_invalid_id'
                                                      .tr,
                                                  isError: true,
                                                );
                                                return;
                                              }
                                              ref
                                                  .read(
                                                    selectedMajorIdProvider
                                                        .notifier,
                                                  )
                                                  .state = major.id;

                                              if (wPage == 0) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            SearchSubjectsPage(
                                                              majorId:
                                                                  major.id!,
                                                            ),
                                                  ),
                                                );
                                              } else if (wPage == 1) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            ProfessorsPage(
                                                              majorId:
                                                                  major.id!,
                                                            ),
                                                  ),
                                                );
                                              } else if (wPage == 2) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            const ManageSubjectsPage(),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    loading:
                        () => const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                    error:
                        (e, _) => Center(
                          child: Padding(
                            padding: EdgeInsets.all(scaleConfig.scale(16)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error,
                                  color: AppColors.error,
                                  size: scaleConfig.scale(40),
                                ),
                                SizedBox(height: scaleConfig.scale(16)),
                                Text(
                                  'error_wifi'.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: scaleConfig.scaleText(16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ),
                ],
              );
            },
            loading:
                () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
            error:
                (e, _) => Center(
                  child: Padding(
                    padding: EdgeInsets.all(scaleConfig.scale(16)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error,
                          color: AppColors.error,
                          size: scaleConfig.scale(40),
                        ),
                        SizedBox(height: scaleConfig.scale(16)),
                        Text(
                          'error_wifi'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: scaleConfig.scaleText(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          );
        },
      ),
    );
  }
}
