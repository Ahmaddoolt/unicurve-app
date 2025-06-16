import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/uni_admin/professors/views/professors_page.dart';
import 'package:unicurve/pages/uni_admin/providers/admin_university_provider.dart';
import 'package:unicurve/pages/uni_admin/providers/majors_provider.dart';
// Import the new provider
import 'package:unicurve/pages/uni_admin/providers/selected_major_provider.dart';
import 'package:unicurve/pages/uni_admin/subjects/manage_subjects_with_search.dart';
// Import the new page we will create
import 'package:unicurve/pages/uni_admin/subjects_terms_tables/manage_subjects_times_page.dart';

class SelectMajorPage extends ConsumerWidget {
  final int wPage;
  const SelectMajorPage({super.key, required this.wPage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = ScaleConfig(context);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        centerTitle: true,
        title: Text(
          'Select Major',
          style: TextStyle(
            color: AppColors.darkTextPrimary,
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
                      'No university assigned',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.darkTextSecondary,
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
                                          color: AppColors.darkTextSecondary,
                                          size: scaleConfig.scale(40),
                                        ),
                                        SizedBox(height: scaleConfig.scale(16)),
                                        Text(
                                          'No majors found',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppColors.darkTextSecondary,
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
                                          color: AppColors.darkBackground,
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
                                              backgroundColor:
                                                  AppColors.darkSurface,
                                              child: Icon(
                                                Icons.school,
                                                color: AppColors.primary,
                                                size: scaleConfig.scale(20),
                                              ),
                                            ),
                                            title: Text(
                                              major.name,
                                              style: TextStyle(
                                                color:
                                                    AppColors.darkTextPrimary,
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
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: const Text(
                                                      'Invalid major ID',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                    behavior:
                                                        SnackBarBehavior
                                                            .floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              // ** KEY CHANGE HERE **
                                              // 1. Update the provider with the selected major's ID
                                              ref
                                                  .read(
                                                    selectedMajorIdProvider
                                                        .notifier,
                                                  )
                                                  .state = major.id;

                                              // 2. Navigate to the correct page
                                              if (wPage == 0) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    // Navigate to the page without passing any arguments
                                                    builder:
                                                        (context) =>
                                                             SearchSubjectsPage(majorId: major.id!,),
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
                                                            ManageSubjectsPage()
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
                                  'Error: ${e.toString().replaceFirst('Exception: ', '')}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.darkTextSecondary,
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
                          'Error: ${e.toString().replaceFirst('Exception: ', '')}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.darkTextSecondary,
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
