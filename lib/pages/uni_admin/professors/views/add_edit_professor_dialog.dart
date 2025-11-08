// lib/pages/uni_admin/professors/views/add_edit_professor_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/glass_loading_overlay.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/professor.dart';
import 'package:unicurve/domain/models/subject.dart';
import 'package:unicurve/pages/uni_admin/professors/professors_supabase_service.dart';
import 'package:unicurve/pages/uni_admin/providers/professors_provider.dart';

class AddEditProfessorDialog extends ConsumerStatefulWidget {
  final int majorId;
  final bool isEdit;
  final Professor? professor;

  const AddEditProfessorDialog({
    super.key,
    required this.majorId,
    required this.isEdit,
    this.professor,
  });

  @override
  AddEditProfessorDialogState createState() => AddEditProfessorDialogState();
}

class AddEditProfessorDialogState
    extends ConsumerState<AddEditProfessorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _searchController;
  List<Subject> _availableSubjects = [];
  List<Subject> _filteredSubjects = [];
  final Map<int, bool> _subjectSelection = {};
  final Map<int, bool> _subjectActiveStatus = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.professor?.name ?? '');
    _searchController = TextEditingController();
    _searchController.addListener(_filterSubjects);
    _fetchSubjectsAndAssignments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterSubjects() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSubjects = _availableSubjects.where((subject) {
        return (subject.name.toLowerCase()).contains(query) ||
            (subject.code.toLowerCase()).contains(query);
      }).toList();
    });
  }

  Future<void> _fetchSubjectsAndAssignments() async {
    setState(() => _isLoading = true);
    final supabaseService = SupabaseService();
    try {
      _availableSubjects = await supabaseService.fetchSubjects(widget.majorId);
      _filteredSubjects = _availableSubjects;
      for (var subject in _availableSubjects) {
        _subjectSelection[subject.id!] = false;
        _subjectActiveStatus[subject.id!] = false;
      }
      if (widget.isEdit && widget.professor != null) {
        final assignments = await supabaseService
            .fetchTeachingAssignments(widget.professor!.id);
        assignments.forEach((subjectId, isActive) {
          if (_subjectSelection.containsKey(subjectId)) {
            _subjectSelection[subjectId] = true;
            _subjectActiveStatus[subjectId] = isActive;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _errorMessage = 'prof_dialog_error_fetch_subjects'
            .trParams({'error': e.toString()});
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfessor() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'prof_dialog_error_name_empty'.tr);
      return;
    }
    if (widget.isEdit && widget.professor == null) {
      setState(() => _errorMessage = 'prof_dialog_error_missing_id'.tr);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final notifier = ref.read(professorsProvider(widget.majorId).notifier);
      if (widget.isEdit) {
        await notifier.editProfessor(
          professor: widget.professor!,
          name: _nameController.text.trim(),
          subjectSelection: _subjectSelection,
          subjectActiveStatus: _subjectActiveStatus,
        );
      } else {
        await notifier.addProfessor(
          name: _nameController.text.trim(),
          subjectSelection: _subjectSelection,
          subjectActiveStatus: _subjectActiveStatus,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.isEdit
                ? 'prof_dialog_success_update'.tr
                : 'prof_dialog_success_add'.tr),
            backgroundColor: AppColors.primary));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            'prof_dialog_error_save'.trParams({'error': e.toString()}));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // --- THIS IS THE KEY FIX: A consistent InputDecoration helper ---
    InputDecoration customInputDecoration({required String labelText}) {
      return InputDecoration(
        labelText: labelText,
        labelStyle: theme.textTheme.labelLarge,
        filled: true,
        fillColor: isDarkMode
            ? Colors.black.withOpacity(0.25)
            : theme.inputDecorationTheme.fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: isDarkMode
              ? BorderSide(color: Colors.white.withOpacity(0.2))
              : BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: scaleConfig.scale(360),
        height: scaleConfig.heightPercentage(0.7),
        child: GlassLoadingOverlay(
          isLoading: _isLoading,
          child: GlassCard(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(scaleConfig.scale(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.isEdit
                        ? 'prof_dialog_edit_title'.tr
                        : 'prof_dialog_add_title'.tr,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontSize: scaleConfig.scaleText(20)),
                  ),
                  SizedBox(height: scaleConfig.scale(24)),
                  TextFormField(
                    controller: _nameController,
                    decoration: customInputDecoration(
                        labelText: 'prof_dialog_name_label'.tr),
                    style: theme.textTheme.bodyLarge,
                    onChanged: (_) => setState(() {}),
                    validator: (val) => val!.trim().isEmpty
                        ? 'prof_dialog_error_name_empty'.tr
                        : null,
                  ),
                  SizedBox(height: scaleConfig.scale(16)),
                  TextFormField(
                    controller: _searchController,
                    decoration: customInputDecoration(
                            labelText: 'prof_dialog_search_hint'.tr)
                        .copyWith(
                            prefixIcon: const Icon(Icons.search,
                                color: AppColors.accent)),
                    style: theme.textTheme.bodyLarge,
                  ),
                  SizedBox(height: scaleConfig.scale(16)),
                  Text(
                    'prof_dialog_select_subjects_title'.tr,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildSubjectsList(theme, scaleConfig),
                  ),
                  if (_errorMessage != null) ...[
                    SizedBox(height: scaleConfig.scale(12)),
                    _buildErrorMessage(),
                  ],
                  SizedBox(height: scaleConfig.scale(16)),
                  _buildActionButtons(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectsList(ThemeData theme, ScaleConfig scaleConfig) {
    if (_filteredSubjects.isEmpty) {
      return Center(
        child: Text(
          'prof_dialog_no_subjects'.tr,
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    return ListView.builder(
      // Changed to ListView.builder for performance
      itemCount: _filteredSubjects.length,
      itemBuilder: (context, index) {
        final subject = _filteredSubjects[index];
        final isSelected = _subjectSelection[subject.id] ?? false;
        return Column(
          children: [
            CheckboxListTile(
              title: Text(
                'prof_dialog_subject_display'.trParams({
                  'name': subject.name,
                  'code': subject.code,
                  'hours': subject.hours.toString(),
                }),
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: subject.isOpen
                        ? theme.textTheme.bodyLarge?.color
                        : Colors.orangeAccent),
              ),
              subtitle: !subject.isOpen
                  ? Text('prof_dialog_subject_not_open'.tr,
                      style: TextStyle(
                          color: Colors.orangeAccent.withOpacity(0.8),
                          fontSize: 12))
                  : null,
              value: isSelected,
              onChanged: _isSaving
                  ? null
                  : (val) => setState(() {
                        _subjectSelection[subject.id!] = val ?? false;
                        if (val == false) {
                          _subjectActiveStatus[subject.id!] = false;
                        }
                      }),
              activeColor: AppColors.accent,
              contentPadding: EdgeInsets.zero,
            ),
            if (isSelected && subject.isOpen)
              Padding(
                padding: EdgeInsets.only(left: scaleConfig.scale(24)),
                child: CheckboxListTile(
                  title: Text('prof_dialog_actively_teaching'.tr,
                      style: theme.textTheme.bodyMedium),
                  value: _subjectActiveStatus[subject.id],
                  onChanged: _isSaving
                      ? null
                      : (val) => setState(() =>
                          _subjectActiveStatus[subject.id!] = val ?? false),
                  activeColor: AppColors.accent,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text('cancel'.tr),
        ),
        const SizedBox(width: 8),
        CustomButton(
          onPressed: _isSaving ? () {} : () => _saveProfessor(),
          text: widget.isEdit ? 'save_button'.tr : 'add_button'.tr,
          gradient: _isSaving
              ? AppColors.disabledGradient
              : AppColors.primaryGradient,
        ),
      ],
    );
  }
}
