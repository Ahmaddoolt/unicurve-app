import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // REPLACE THE ENTIRE BUILD METHOD IN ProfessorsPage

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = ScaleConfig(context);
    final professorsState = ref.watch(professorsProvider(majorId));
    final professorsNotifier = ref.read(professorsProvider(majorId).notifier);
    // FIX: Use the new, correct provider to get details for THIS majorId
    final majorDetailsAsync = ref.watch(majorDetailsProvider(majorId));

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
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.darkBackground,
        // FIX: Use the new provider for the title
        title: majorDetailsAsync.when(
          data:
              (major) => Text(
                'Professors for ${major.name}',
                style: TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: scaleConfig.scaleText(18),
                ),
                overflow: TextOverflow.ellipsis,
              ),
          loading: () => const Text('Loading Major...'),
          error: (_, __) => const Text('Manage Professors'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(scaleConfig.scale(16)),
            child: TextField(
              controller: professorsNotifier.searchController,
              decoration: InputDecoration(
                hintText: 'Search professors by name...',
                hintStyle: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: scaleConfig.scaleText(14),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.accent,
                  size: scaleConfig.scale(20),
                ),
                filled: true,
                fillColor: AppColors.darkBackground,
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
                color: AppColors.darkTextPrimary,
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
                          ? 'No professors found. Add one!'
                          : 'No matching professors found.',
                      style: TextStyle(
                        color: AppColors.darkTextSecondary,
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
                        color: AppColors.darkBackground,
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
                            backgroundColor: AppColors.darkSurface,
                            child: Icon(
                              Icons.person,
                              color: AppColors.accent,
                              size: scaleConfig.scale(24),
                            ),
                          ),
                          title: Text(
                            professor.name ?? 'Unknown',
                            style: TextStyle(
                              color: AppColors.darkTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: scaleConfig.scaleText(16),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          // FIX: Use the new provider for the subtitle
                          subtitle: majorDetailsAsync.when(
                            data:
                                (major) => Text(
                                  'Major: ${major.name}',
                                  style: TextStyle(
                                    color: AppColors.darkTextSecondary,
                                    fontSize: scaleConfig.scaleText(14),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            loading: () => const Text('Loading Major...'),
                            error: (_, __) => const Text('Major: N/A'),
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
                            color: AppColors.darkSurface,
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
                                          'Edit',
                                          style: TextStyle(
                                            color: AppColors.darkTextPrimary,
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
                                          'Delete',
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
                          'Error loading professors: $error',
                          style: TextStyle(
                            color: AppColors.darkTextSecondary,
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
                            'Retry',
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
    showDialog(
      context: context,
      builder:
          (alertDialogContext) => AlertDialog(
            backgroundColor: AppColors.darkSurface,
            title: const Text(
              'Delete Professor',
              style: TextStyle(color: AppColors.darkTextPrimary),
            ),
            content: const Text(
              'Are you sure you want to delete this professor? This action cannot be undone.',
              style: TextStyle(color: AppColors.darkTextPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(alertDialogContext).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.accent),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(alertDialogContext).pop(); // Close dialog
                  try {
                    await ref
                        .read(professorsProvider(majorId).notifier)
                        .deleteProfessor(professor.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Professor deleted.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting professor: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
  }
}
