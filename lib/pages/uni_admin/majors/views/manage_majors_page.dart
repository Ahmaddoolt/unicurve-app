import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_floadt_action_button.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/major.dart';
import 'package:unicurve/pages/uni_admin/majors/views/add_major_dialog.dart';
import 'package:unicurve/pages/uni_admin/majors/views/edit_major_dialog.dart';
import 'package:unicurve/pages/uni_admin/majors/widgets/major_list_tile.dart';
import 'package:unicurve/pages/uni_admin/providers/admin_university_provider.dart';
import 'package:unicurve/pages/uni_admin/providers/majors_provider.dart';

class ManageMajorsPage extends ConsumerWidget {
  const ManageMajorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = ScaleConfig(context);
    final adminUniversityAsync = ref.watch(adminUniversityProvider);
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: lighterColor,
      appBar: CustomAppBar(
        title: 'manage_majors_page_title'.tr,
        centerTitle: true,
        backgroundColor: darkerColor,
      ),
      body: adminUniversityAsync.when(
        data: (adminUniversity) {
          if (adminUniversity == null) {
            return Center(child: Text('error_no_university_assigned'.tr));
          }

          final universityId = adminUniversity['university_id'] as int;
          final majorsAsync = ref.watch(majorsProvider(universityId));

          return majorsAsync.when(
            data:
                (majors) =>
                    majors.isEmpty
                        ? Center(child: Text('majors_empty_list_prompt'.tr))
                        : RefreshIndicator(
                          onRefresh: () async {
                            ref.invalidate(majorsProvider(universityId));
                          },
                          child: ListView.builder(
                            padding: EdgeInsets.all(scaleConfig.scale(16)),
                            itemCount: majors.length,
                            itemBuilder: (context, index) {
                              final major = majors[index];
                              return MajorListTile(
                                major: major,
                                onEdit:
                                    () => _showEditDialog(context, major, ref),
                              );
                            },
                          ),
                        ),
            loading:
                () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
            error:
                (e, _) => Center(
                  child: Text(
                    'error_generic'.trParams({'error': e.toString()}),
                  ),
                ),
          );
        },
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        error:
            (e, _) => Center(
              child: Text('error_generic'.trParams({'error': e.toString()})),
            ),
      ),
      floatingActionButton: CustomFAB(
        onPressed: () {
          showDialog(
            context: context,
            builder:
                (context) => AddMajorDialog(
                  adminUniversity: adminUniversityAsync.value,
                  onSuccess: () {
                    ref.invalidate(
                      majorsProvider(
                        adminUniversityAsync.value!['university_id'],
                      ),
                    );
                  },
                ),
          );
        },
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    Major major,
    WidgetRef ref,
  ) async {
    await showDialog(
      context: context,
      builder:
          (context) => EditMajorDialog(
            major: major,
            onSuccess: () {
              ref.invalidate(majorsProvider(major.universityId));
            },
          ),
    );
  }
}
