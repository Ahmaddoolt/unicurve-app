import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_floadt_action_button.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/professor.dart';
import 'package:unicurve/pages/uni_admin/professors/views/add_edit_professor_dialog.dart';
import 'package:unicurve/pages/uni_admin/professors/views/professor_details_dialog.dart';
import 'package:unicurve/pages/uni_admin/providers/majors_provider.dart';
import 'package:unicurve/pages/uni_admin/providers/professors_provider.dart';

class ProfessorsPage extends ConsumerWidget {
  final int majorId;

  const ProfessorsPage({super.key, required this.majorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = ScaleConfig(context);
    final professorsState = ref.watch(professorsProvider(majorId));
    final professorsNotifier = ref.read(professorsProvider(majorId).notifier);
    final majorDetailsAsync = ref.watch(majorDetailsProvider(majorId));

    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      floatingActionButton: CustomFAB(
        onPressed:
            () => showDialog(
              context: context,
              builder:
                  (_) =>
                      AddEditProfessorDialog(majorId: majorId, isEdit: false),
            ),
      ),
      backgroundColor: lighterColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: darkerColor,
        title: majorDetailsAsync.when(
          data:
              (major) => Text(
                'prof_page_title'.trParams({'majorName': major.name}),
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: scaleConfig.scaleText(18),
                ),
                overflow: TextOverflow.ellipsis,
              ),
          loading: () => Text('loading_text'.tr),
          error: (_, __) => Text('prof_page_title_fallback'.tr),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(scaleConfig.scale(16)),
            child: TextField(
              controller: professorsNotifier.searchController,
              decoration: InputDecoration(
                hintText: 'prof_page_search_hint'.tr,
                hintStyle: TextStyle(
                  color: secondaryTextColor,
                  fontSize: scaleConfig.scaleText(14),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.accent,
                  size: scaleConfig.scale(20),
                ),
                filled: true,
                fillColor: darkerColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: scaleConfig.scale(12),
                  horizontal: scaleConfig.scale(16),
                ),
              ),
              style: TextStyle(
                color: primaryTextColor,
                fontSize: scaleConfig.scaleText(14),
              ),
            ),
          ),
          Expanded(
            child: professorsState.when(
              data: (professors) {
                if (professors.isEmpty) {
                  return Center(
                    child: Text(
                      professorsNotifier.searchController.text.isEmpty
                          ? 'prof_page_no_professors_found'.tr
                          : 'prof_page_no_matching_professors'.tr,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: scaleConfig.scaleText(16),
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh:
                      () =>
                          ref
                              .read(professorsProvider(majorId).notifier)
                              .fetchProfessors(),
                  child: ListView.builder(
                    itemCount: professors.length,
                    itemBuilder: (context, index) {
                      final professor = professors[index];
                      return Card(
                        color: darkerColor,
                        elevation: 2,
                        margin: EdgeInsets.symmetric(
                          horizontal: scaleConfig.scale(16),
                          vertical: scaleConfig.scale(8),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            scaleConfig.scale(12),
                          ),
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 2.5,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(scaleConfig.scale(16)),
                          leading: CircleAvatar(
                            radius: scaleConfig.scale(20),
                            backgroundColor: lighterColor,
                            child: Icon(
                              Icons.person,
                              color: AppColors.accent,
                              size: scaleConfig.scale(24),
                            ),
                          ),
                          title: Text(
                            professor.name ?? 'prof_details_unknown_prof'.tr,
                            style: TextStyle(
                              color: primaryTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: scaleConfig.scaleText(16),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: majorDetailsAsync.when(
                            data:
                                (major) => Text(
                                  'prof_details_major_label_with_name'.trParams(
                                    {'majorName': major.name},
                                  ),
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: scaleConfig.scaleText(14),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            loading: () => Text('loading_text'.tr),
                            error:
                                (_, __) => Text(
                                  'prof_details_major_label_with_name'.trParams(
                                    {'majorName': 'not_available'.tr},
                                  ),
                                ),
                          ),
                          onTap:
                              () => showDialog(
                                context: context,
                                builder:
                                    (_) => ProfessorDetailsDialog(
                                      professor: professor,
                                      majorId: majorId,
                                    ),
                              ),
                          trailing: PopupMenuButton<String>(
                            color: lighterColor,
                            icon: Icon(
                              Icons.more_vert,
                              color: AppColors.accent,
                              size: scaleConfig.scale(20),
                            ),
                            onSelected: (value) {
                              if (value == 'edit') {
                                showDialog(
                                  context: context,
                                  builder:
                                      (_) => AddEditProfessorDialog(
                                        majorId: majorId,
                                        isEdit: true,
                                        professor: professor,
                                      ),
                                );
                              } else if (value == 'delete') {
                                _showDeleteConfirmationDialog(
                                  context,
                                  ref,
                                  professor,
                                );
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.edit,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'popup_edit'.tr,
                                          style: TextStyle(
                                            color: primaryTextColor,
                                            fontSize: scaleConfig.scaleText(14),
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
                                          Icons.delete_forever,
                                          color: AppColors.error,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'popup_delete'.tr,
                                          style: TextStyle(
                                            color: AppColors.error,
                                            fontSize: scaleConfig.scaleText(14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
              error:
                  (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'prof_page_error_loading'.trParams({
                            'error': error.toString(),
                          }),
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: scaleConfig.scaleText(16),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed:
                              () =>
                                  ref
                                      .read(
                                        professorsProvider(majorId).notifier,
                                      )
                                      .fetchProfessors(),
                          child: Text(
                            'retry_button'.tr,
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: scaleConfig.scaleText(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    Professor professor,
  ) {
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;

    showDialog(
      context: context,
      builder:
          (alertDialogContext) => AlertDialog(
            backgroundColor: lighterColor,
            title: Text(
              'prof_delete_dialog_title'.tr,
              style: TextStyle(color: primaryTextColor),
            ),
            content: Text(
              'prof_delete_confirmation'.tr,
              style: TextStyle(color: primaryTextColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(alertDialogContext).pop(),
                child: Text(
                  'cancel'.tr,
                  style: const TextStyle(color: AppColors.accent),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(alertDialogContext).pop();
                  try {
                    await ref
                        .read(professorsProvider(majorId).notifier)
                        .deleteProfessor(professor.id);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'prof_error_delete'.trParams({
                              'error': e.toString(),
                            }),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  'delete_button'.tr,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
  }
}
