// lib/pages/uni_admin/professors/views/professors_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_floadt_action_button.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/glass_loading_overlay.dart';
import 'package:unicurve/core/utils/gradient_icon.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final professorsState = ref.watch(professorsProvider(majorId));
    final professorsNotifier = ref.read(professorsProvider(majorId).notifier);
    final majorDetailsAsync = ref.watch(majorDetailsProvider(majorId));

    final appBar = CustomAppBar(
      useGradient: !isDarkMode,
      titleWidget: majorDetailsAsync.when(
        data: (major) => Text(
          'prof_page_title'.trParams({'majorName': major.name}),
          overflow: TextOverflow.ellipsis,
        ),
        loading: () => Text('loading_text'.tr),
        error: (_, __) => Text('prof_page_title_fallback'.tr),
      ),
    );

    final bodyContent = GlassLoadingOverlay(
      isLoading: professorsState.isLoading && !professorsState.hasValue,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(scaleConfig.scale(16),
                scaleConfig.scale(16), scaleConfig.scale(16), 0),
            child: isDarkMode
                ? GlassCard(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildSearchField(theme, professorsNotifier),
                  )
                : _buildSearchField(theme, professorsNotifier),
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
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: scaleConfig.scaleText(16),
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(professorsProvider(majorId).notifier)
                      .fetchProfessors(),
                  child: ListView.builder(
                    padding: EdgeInsets.all(scaleConfig.scale(8)),
                    itemCount: professors.length,
                    itemBuilder: (context, index) {
                      final professor = professors[index];
                      return _ProfessorListTile(
                        professor: professor,
                        majorId: majorId,
                      );
                    },
                  ),
                );
              },
              loading: () => const SizedBox.shrink(), // Keep UI static
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'prof_page_error_loading'
                          .trParams({'error': error.toString()}),
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: scaleConfig.scaleText(16),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(professorsProvider(majorId).notifier)
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

    if (isDarkMode) {
      return GradientScaffold(
        appBar: appBar,
        body: bodyContent,
        floatingActionButton: CustomFAB(
          onPressed: () => showDialog(
            context: context,
            builder: (_) =>
                AddEditProfessorDialog(majorId: majorId, isEdit: false),
          ),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        body: bodyContent,
        floatingActionButton: CustomFAB(
          onPressed: () => showDialog(
            context: context,
            builder: (_) =>
                AddEditProfessorDialog(majorId: majorId, isEdit: false),
          ),
        ),
      );
    }
  }

  Widget _buildSearchField(ThemeData theme, ProfessorsNotifier notifier) {
    return TextField(
      controller: notifier.searchController,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: 'prof_page_search_hint'.tr,
        fillColor: theme.brightness == Brightness.dark
            ? Colors.transparent
            : theme.inputDecorationTheme.fillColor,
        border: theme.brightness == Brightness.dark
            ? InputBorder.none
            : theme.inputDecorationTheme.border,
      ).applyDefaults(theme.inputDecorationTheme).copyWith(
            prefixIcon:
                Icon(Icons.search, color: theme.textTheme.bodyMedium?.color),
          ),
    );
  }
}

class _ProfessorListTile extends ConsumerWidget {
  final Professor professor;
  final int majorId;

  const _ProfessorListTile({required this.professor, required this.majorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = ScaleConfig(context);
    final theme = Theme.of(context);

    return GlassCard(
      margin: EdgeInsets.symmetric(
        horizontal: scaleConfig.scale(8),
        vertical: scaleConfig.scale(6),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
            vertical: scaleConfig.scale(8), horizontal: scaleConfig.scale(16)),
        leading: GradientIcon(
            icon: Icons.person_outline, size: scaleConfig.scale(32)),
        title: Text(
          professor.name ?? 'prof_details_unknown_prof'.tr,
          style:
              theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => showDialog(
          context: context,
          builder: (_) => ProfessorDetailsDialog(
            professor: professor,
            majorId: majorId,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: theme.textTheme.bodyMedium?.color,
          ),
          onSelected: (value) {
            if (value == 'edit') {
              showDialog(
                context: context,
                builder: (_) => AddEditProfessorDialog(
                  majorId: majorId,
                  isEdit: true,
                  professor: professor,
                ),
              );
            } else if (value == 'delete') {
              _showDeleteConfirmationDialog(context, ref, professor);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                const Icon(Icons.edit_outlined, color: AppColors.accent),
                const SizedBox(width: 8),
                Text('popup_edit'.tr),
              ]),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                const Icon(Icons.delete_outline, color: AppColors.error),
                const SizedBox(width: 8),
                Text('popup_delete'.tr,
                    style: const TextStyle(color: AppColors.error)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, WidgetRef ref, Professor professor) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (alertDialogContext) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: GlassCard(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('prof_delete_dialog_title'.tr,
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Text('prof_delete_confirmation'.tr,
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(alertDialogContext).pop(),
                      child: Text('cancel'.tr),
                    ),
                    CustomButton(
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
                                content: Text('prof_error_delete'
                                    .trParams({'error': e.toString()})),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      text: 'delete_button'.tr,
                      backgroundColor: AppColors.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
