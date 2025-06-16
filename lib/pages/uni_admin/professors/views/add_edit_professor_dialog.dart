import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/core/utils/colors.dart';
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
  _AddEditProfessorDialogState createState() => _AddEditProfessorDialogState();
}

class _AddEditProfessorDialogState extends ConsumerState<AddEditProfessorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _searchController;
  List<Subject> _availableSubjects = [];
  List<Subject> _filteredSubjects = [];
  Map<int, bool> _subjectSelection = {};
  Map<int, bool> _subjectActiveStatus = {};
  bool _isLoading = false;
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
        return (subject.name.toLowerCase()).contains(query) || (subject.code.toLowerCase()).contains(query);
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
        _subjectSelection[subject.id ?? 0] = false;
        _subjectActiveStatus[subject.id ?? 0] = false;
      }
      if (widget.isEdit && widget.professor != null) {
        final assignments = await supabaseService.fetchTeachingAssignments(widget.professor!.id);
        for (var entry in assignments.entries) {
          if (_subjectSelection.containsKey(entry.key)) {
            _subjectSelection[entry.key] = true;
            _subjectActiveStatus[entry.key] = entry.value;
          }
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching subjects: $e';
      });
    }
  }

  Future<void> _saveProfessor() async {
    if (_nameController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in the professor name');
      return;
    }
    if (widget.isEdit && widget.professor == null) {
      setState(() => _errorMessage = 'Error: Professor ID is missing');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Professor ${widget.isEdit ? 'updated' : 'added'} successfully.'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error saving professor: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // FIX: The entire build method is refactored to use a Column instead of a Stack.
  @override
  Widget build(BuildContext context) {
    final scaleConfig = ScaleConfig(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        side: const BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      backgroundColor: AppColors.darkBackground,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: scaleConfig.scale(320),
          maxHeight: scaleConfig.scale(550), // Increased height slightly for more room
        ),
        // FIX: Replaced Stack with a simple Padding and Column structure.
        child: Padding(
          padding: EdgeInsets.all(scaleConfig.scale(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Let the column size itself.
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children horizontally.
            children: [
              Text(
                widget.isEdit ? 'Edit Professor' : 'Add Professor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: scaleConfig.scaleText(18),
                ),
              ),
              SizedBox(height: scaleConfig.scale(16)),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Professor Name',
                  labelStyle: TextStyle(color: AppColors.darkTextSecondary),
                  filled: true,
                  fillColor: AppColors.darkSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                    borderSide: BorderSide(color: AppColors.darkTextSecondary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                    borderSide: BorderSide(color: AppColors.darkTextSecondary),
                  ),
                  errorText: _nameController.text.isEmpty ? 'Name is required' : null,
                ),
                style: TextStyle(color: AppColors.darkTextPrimary),
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: scaleConfig.scale(16)),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search subjects by name or code...',
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
              SizedBox(height: scaleConfig.scale(16)),
              Text(
                'Select Subjects:',
                style: TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: scaleConfig.scaleText(16),
                ),
              ),
              SizedBox(height: scaleConfig.scale(4)),
              // FIX: The scrollable list is now in an Expanded widget, so it takes
              // up the available space and can scroll freely.
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _filteredSubjects.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(8)),
                            child: Text(
                              'No subjects available for this major',
                              style: TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: scaleConfig.scaleText(14),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: _filteredSubjects.map((subject) {
                                final isChecked = _subjectSelection[subject.id ?? 0]!;
                                return Column(
                                  children: [
                                    CheckboxListTile(
                                      title: Text(
                                        '${subject.name} (${subject.code}, Hours: ${subject.hours})${subject.isOpen ? '' : ' - Not Open'}',
                                        style: TextStyle(
                                          color: subject.isOpen ? AppColors.primary : Colors.orange,
                                          fontSize: scaleConfig.scaleText(14),
                                        ),
                                      ),
                                      value: isChecked,
                                      onChanged: _isSaving
                                          ? null
                                          : (bool? value) {
                                              setState(() {
                                                _subjectSelection[subject.id ?? 0] = value!;
                                                if (!value) {
                                                  _subjectActiveStatus[subject.id ?? 0] = false;
                                                }
                                              });
                                            },
                                      activeColor: AppColors.accent,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: scaleConfig.scale(8),
                                        vertical: scaleConfig.scale(2),
                                      ),
                                    ),
                                    if (isChecked && subject.isOpen)
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: scaleConfig.scale(48),
                                          right: scaleConfig.scale(8),
                                        ),
                                        child: CheckboxListTile(
                                          title: Text(
                                            'Actively Teaching',
                                            style: TextStyle(
                                              color: AppColors.darkTextPrimary,
                                              fontSize: scaleConfig.scaleText(12),
                                            ),
                                          ),
                                          value: _subjectActiveStatus[subject.id ?? 0],
                                          onChanged: _isSaving
                                              ? null
                                              : (bool? value) {
                                                  setState(() {
                                                    _subjectActiveStatus[subject.id ?? 0] = value!;
                                                  });
                                                },
                                          activeColor: AppColors.accent,
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: scaleConfig.scale(12)),
                Container(
                  padding: EdgeInsets.all(scaleConfig.scale(12)),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error,
                        color: AppColors.darkTextSecondary,
                        size: scaleConfig.scale(20),
                      ),
                      SizedBox(width: scaleConfig.scale(8)),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: scaleConfig.scaleText(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: scaleConfig.scale(8)),
              // FIX: The action buttons are now the last item in the Column,
              // ensuring they are always visible and below the content.
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving || _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: scaleConfig.scaleText(14),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isSaving || _isLoading ? null : _saveProfessor,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.accent,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.isEdit ? 'Save' : 'Add',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: scaleConfig.scaleText(14),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}