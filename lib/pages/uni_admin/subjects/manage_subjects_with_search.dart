// lib/pages/uni_admin/subjects/manage_subjects_with_search.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_floadt_action_button.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/gradient_icon.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/core/utils/scale_config.dart';
// --- NEW: Import the reusable overlay widget ---
import 'package:unicurve/core/utils/glass_loading_overlay.dart';
import 'package:unicurve/pages/uni_admin/subjects/add_subject.dart';
import 'package:unicurve/pages/uni_admin/subjects/edit_subject_dialog.dart';
import 'package:unicurve/pages/uni_admin/subjects/subjects_relationships/manage_subjects_relationships.dart'
    as rel_manager;

final subjectsAndRequirementsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, majorId) async {
  final supabase = Supabase.instance.client;
  final subjectsFuture = supabase
      .from('subjects')
      .select('*, subject_professors(professors(name))')
      .eq('major_id', majorId)
      .order('name', ascending: true);

  final requirementsFuture = supabase
      .from('major_requirements')
      .select('id, requirement_name')
      .eq('major_id', majorId);

  final majorFuture = supabase
      .from('majors')
      .select('name, university_id')
      .eq('id', majorId)
      .single();

  final results =
      await Future.wait([subjectsFuture, requirementsFuture, majorFuture]);

  final subjects = List<Map<String, dynamic>>.from(results[0] as List);
  final requirementsResponse = results[1] as List;
  final majorResponse = results[2] as Map;

  final requirementsMap = {
    for (var req in requirementsResponse)
      (req['id'] as int): req['requirement_name'] as String,
  };

  return {
    'subjects': subjects,
    'requirementsMap': requirementsMap,
    'majorName': majorResponse['name'],
    'universityId': majorResponse['university_id'],
  };
});

class SearchSubjectsPage extends ConsumerStatefulWidget {
  final int majorId;
  const SearchSubjectsPage({super.key, required this.majorId});

  @override
  ConsumerState<SearchSubjectsPage> createState() => _SearchSubjectsPageState();
}

class _SearchSubjectsPageState extends ConsumerState<SearchSubjectsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterListener() => setState(() {});

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterListener);
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final subjectsDataAsync =
        ref.watch(subjectsAndRequirementsProvider(widget.majorId));

    final data = subjectsDataAsync.valueOrNull;
    final allSubjects = data?['subjects'] as List<Map<String, dynamic>>? ?? [];
    final requirementsMap = data?['requirementsMap'] as Map<int, String>? ?? {};
    final majorName = data?['majorName'] as String? ?? '...';
    final universityId = data?['universityId'] as int?;

    final query = _searchController.text.toLowerCase();
    final filteredSubjects = allSubjects.where((subject) {
      final nameMatch =
          subject['name'].toString().toLowerCase().contains(query);
      final codeMatch =
          subject['code'].toString().toLowerCase().contains(query);
      return nameMatch || codeMatch;
    }).toList();

    final appBar = CustomAppBar(
      useGradient: !isDarkMode,
      title: majorName,
      actions: [
        IconButton(
          icon: const Icon(Icons.lan_outlined),
          tooltip: 'manage_relationships_tooltip'.tr,
          onPressed: () {
            if (universityId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      rel_manager.ManageSubjectsRelationshipsPage(
                    subjects: allSubjects,
                    universityId: universityId,
                    majorId: widget.majorId,
                  ),
                ),
              );
            }
          },
        ),
      ],
    );

    // --- THE KEY CHANGE: Using the new GlassLoadingOverlay widget ---
    final bodyContent = GlassLoadingOverlay(
      isLoading: subjectsDataAsync.isLoading && !subjectsDataAsync.hasValue,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(scaleConfig.scale(16),
                scaleConfig.scale(16), scaleConfig.scale(16), 0),
            child: isDarkMode
                ? GlassCard(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildSearchField(theme),
                  )
                : _buildSearchField(theme),
          ),
          Expanded(
            child: subjectsDataAsync.when(
              data: (_) {
                if (filteredSubjects.isEmpty && allSubjects.isNotEmpty) {
                  return Center(
                    child: Text(
                      'manage_subjects_no_match_search'.tr,
                      style:
                          TextStyle(color: theme.textTheme.bodyMedium?.color),
                    ),
                  );
                }
                if (allSubjects.isEmpty) {
                  return Center(
                    child: Text(
                      'manage_subjects_no_subjects_found'.tr,
                      style:
                          TextStyle(color: theme.textTheme.bodyMedium?.color),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(
                      subjectsAndRequirementsProvider(widget.majorId).future),
                  child: ListView.builder(
                    padding: EdgeInsets.all(scaleConfig.scale(16)),
                    itemCount: filteredSubjects.length,
                    itemBuilder: (context, index) {
                      final subject = filteredSubjects[index];
                      return _SubjectListTile(
                        subject: subject,
                        onTap: () =>
                            _showSubjectDetailsDialog(subject, requirementsMap),
                        onEdit: () => _editSubject(subject, requirementsMap),
                        onDelete: () => _deleteSubject(subject),
                      );
                    },
                  ),
                );
              },
              loading: () => const SizedBox.shrink(), // Keep UI static
              error: (err, stack) => Center(
                child:
                    Text('error_generic'.trParams({'error': err.toString()})),
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
        floatingActionButton: _buildFAB(context, ref),
      );
    } else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        body: bodyContent,
        floatingActionButton: _buildFAB(context, ref),
      );
    }
  }

  Widget _buildFAB(BuildContext context, WidgetRef ref) {
    return CustomFAB(
      onPressed: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => const AddSubjectBasicPage()),
        );
        if (result == true) {
          ref.invalidate(subjectsAndRequirementsProvider(widget.majorId));
        }
      },
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: 'search_subjects_hint'.tr,
        fillColor: theme.brightness == Brightness.dark
            ? Colors.transparent
            : theme.inputDecorationTheme.fillColor,
        border: theme.brightness == Brightness.dark
            ? InputBorder.none
            : theme.inputDecorationTheme.border,
        enabledBorder: theme.brightness == Brightness.dark
            ? InputBorder.none
            : theme.inputDecorationTheme.enabledBorder,
        focusedBorder: theme.brightness == Brightness.dark
            ? InputBorder.none
            : theme.inputDecorationTheme.focusedBorder,
      ).applyDefaults(theme.inputDecorationTheme).copyWith(
            prefixIcon:
                Icon(Icons.search, color: theme.textTheme.bodyMedium?.color),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear,
                        color: theme.textTheme.bodyMedium?.color),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
          ),
    );
  }

  Future<void> _deleteSubject(Map<String, dynamic> subject) async {
    final int? subjectId = subject['id'];
    if (subjectId == null) {
      showFeedbackSnackbar(context, 'delete_subject_error_invalid'.tr,
          isError: true);
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.brightness == Brightness.dark
              ? Colors.transparent
              : theme.cardColor,
          elevation: 0,
          contentPadding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: GlassCard(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('manage_subjects_delete_title'.tr,
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Text(
                      'delete_subject_confirm'
                          .trParams({'name': subject['name']}),
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('cancel'.tr),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('delete_button'.tr,
                            style: const TextStyle(color: AppColors.error)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('subject_professors')
          .delete()
          .eq('subject_id', subjectId);
      await supabase.from('subject_relationships').delete().or(
          'source_subject_id.eq.$subjectId,target_subject_id.eq.$subjectId');
      await supabase.from('subjects').delete().eq('id', subjectId);

      if (mounted) {
        showFeedbackSnackbar(context, 'manage_subjects_delete_success'.tr);
        ref.invalidate(subjectsAndRequirementsProvider(widget.majorId));
      }
    } catch (e) {
      if (mounted) {
        showFeedbackSnackbar(context, 'error_wifi'.tr, isError: true);
      }
    }
  }

  Future<void> _editSubject(
      Map<String, dynamic> subject, Map<int, String> requirementsMap) async {
    final updatedSubject = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditSubjectDialog(
        subject: subject,
        requirementsMap: requirementsMap,
        onSuccess: (updatedData) {
          Navigator.of(context).pop(updatedData);
        },
      ),
    );

    if (updatedSubject != null && mounted) {
      showFeedbackSnackbar(context, 'manage_subjects_update_success'.tr);
      ref.invalidate(subjectsAndRequirementsProvider(widget.majorId));
    }
  }

  void _showSubjectDetailsDialog(
    Map<String, dynamic> subject,
    Map<int, String> requirementsMap,
  ) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    final String typeName =
        requirementsMap[subject['type']] ?? 'uncategorized_label'.tr;
    final List<dynamic> professorLinks = subject['subject_professors'] ?? [];
    final List<String> professorNames = professorLinks
        .map((link) => link['professors']?['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.brightness == Brightness.dark
            ? Colors.transparent
            : theme.cardColor,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: GlassCard(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject['name']?.toString() ?? 'unknown_subject'.tr,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontSize: scaleConfig.scaleText(20)),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                      label: 'code_label'.tr,
                      value: subject['code']?.toString() ?? 'N/A',
                      icon: Icons.code),
                  _buildDetailRow(
                      label: 'add_subject_hours_label'.tr,
                      value: 'hours_label'
                          .trParams({'hours': '${subject['hours'] ?? 0}'}),
                      icon: Icons.access_time),
                  _buildDetailRow(
                      label: 'level_label'.tr,
                      value: subject['level']?.toString() ?? 'N/A',
                      icon: Icons.trending_up),
                  _buildDetailRow(
                      label: 'type_label'.tr,
                      value: typeName,
                      icon: Icons.category),
                  _buildDetailRow(
                      label: 'open_for_reg_label'.tr,
                      value: subject['is_open'] == true ? 'yes'.tr : 'no'.tr,
                      icon: subject['is_open'] == true
                          ? Icons.check_circle_outline
                          : Icons.highlight_off,
                      iconColor: subject['is_open'] == true
                          ? AppColors.primary
                          : AppColors.error),
                  _buildDetailRow(
                      label: 'description_label'.tr,
                      value: subject['description']?.toString() ??
                          'no_description_provided'.tr,
                      icon: Icons.description_outlined),
                  _buildDetailRow(
                      label: 'professors_label'.tr,
                      value: professorNames.isNotEmpty
                          ? professorNames.join(', ')
                          : 'no_professors_listed'.tr,
                      icon: Icons.person_search_outlined),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CustomButton(
                      onPressed: () => Navigator.pop(context),
                      text: 'close_button'.tr,
                      gradient: AppColors.primaryGradient,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      {required String label,
      required String value,
      required IconData icon,
      Color? iconColor}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(value,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectListTile extends StatelessWidget {
  final Map<String, dynamic> subject;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectListTile({
    required this.subject,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaleConfig = context.scaleConfig;

    return GlassCard(
      margin: EdgeInsets.only(bottom: scaleConfig.scale(12)),
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.only(
            left: scaleConfig.scale(16),
            top: scaleConfig.scale(8),
            bottom: scaleConfig.scale(8),
            right: scaleConfig.scale(4)),
        leading: GradientIcon(
          icon: Icons.book_outlined,
          size: scaleConfig.scale(30),
        ),
        title: Text(
          subject['name'],
          style:
              theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${subject['code']} - ${'hours_label'.trParams({
                'hours': subject['hours'].toString()
              })}',
          style: theme.textTheme.bodyMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  color: theme.textTheme.bodyMedium?.color),
              tooltip: 'edit_subject_dialog_title'.tr,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'manage_subjects_delete_title'.tr,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
