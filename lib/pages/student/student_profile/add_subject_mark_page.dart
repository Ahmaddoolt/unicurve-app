// lib/pages/student/student_profile/add_subject_mark_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/glass_loading_overlay.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/student/best_table_term/providers/schedule_repository.dart';
import 'package:unicurve/pages/student/student_profile/providers/academic_profile_provider.dart';

class AddSubjectMarkPage extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> takenSubjects;
  final String? universityType;
  final bool isEditMode;
  final int? recordId;
  final int? initialSubjectId;
  final String? initialSubjectName;
  final int? initialMark;

  const AddSubjectMarkPage({
    super.key,
    required this.takenSubjects,
    required this.universityType,
    this.isEditMode = false,
    this.recordId,
    this.initialSubjectId,
    this.initialSubjectName,
    this.initialMark,
  });

  @override
  ConsumerState<AddSubjectMarkPage> createState() => _AddSubjectMarkPageState();
}

class _AddSubjectMarkPageState extends ConsumerState<AddSubjectMarkPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _markController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  int? _selectedSubjectId;

  List<Map<String, dynamic>> _eligibleSubjects = [];

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _selectedSubjectId = widget.initialSubjectId;
      _markController.text = widget.initialMark.toString();
      setState(() => _isLoading = false);
    } else {
      _fetchEligibleSubjects();
    }
  }

  @override
  void dispose() {
    _markController.dispose();
    super.dispose();
  }

  Future<void> _fetchEligibleSubjects() async {
    setState(() => _isLoading = true);
    _errorMessage = null;
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in.');

      final studentRes = await supabase
          .from('students')
          .select('major_id')
          .eq('user_id', userId)
          .single();
      final majorId = studentRes['major_id'];
      if (majorId == null) throw Exception('Student not assigned to a major.');

      final allSubjectsRes = await supabase
          .from('subjects')
          .select('id, name, code')
          .eq('major_id', majorId);
      final List<Map<String, dynamic>> allSubjects = List.from(allSubjectsRes);

      final relationshipsRes = await supabase
          .from('subject_relationships')
          .select('source_subject_id, target_subject_id')
          .eq('relationship_type', 'PREREQUISITE');
      final List<Map<String, dynamic>> relationships =
          List.from(relationshipsRes);

      final passedSubjectIds = widget.takenSubjects
          .where((s) => s['status'] == 'passed' && s['subjects'] != null)
          .map<int>((s) => s['subjects']['id'] as int)
          .toSet();

      final takenSubjectIds = widget.takenSubjects
          .where((s) => s['subjects'] != null)
          .map<int>((s) => s['subjects']['id'] as int)
          .toSet();

      List<Map<String, dynamic>> eligible = [];
      for (var subject in allSubjects) {
        final subjectId = subject['id'];
        if (takenSubjectIds.contains(subjectId)) continue;

        final prerequisites = relationships
            .where((r) => r['target_subject_id'] == subjectId)
            .map<int>((r) => r['source_subject_id'] as int)
            .toSet();

        if (passedSubjectIds.containsAll(prerequisites)) {
          eligible.add(subject);
        }
      }

      if (mounted) setState(() => _eligibleSubjects = eligible);
    } catch (e) {
      if (mounted) _errorMessage = 'error_load_subjects'.tr;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final mark = int.parse(_markController.text);
      final int passMark = widget.universityType == 'Public' ? 60 : 50;
      final status = mark >= passMark ? 'passed' : 'failed';

      if (widget.isEditMode) {
        await supabase.from('student_taken_subjects').update(
            {'mark': mark, 'status': status}).eq('id', widget.recordId!);
      } else {
        final userId = supabase.auth.currentUser!.id;
        await supabase.from('student_taken_subjects').insert({
          'student_user_id': userId,
          'subject_id': _selectedSubjectId,
          'mark': mark,
          'status': status,
        });
      }

      ref.invalidate(scheduleDataCacheProvider);
      ref.invalidate(academicProfileProvider);

      if (mounted) {
        final action = widget.isEditMode ? 'updated'.tr : 'added'.tr;
        showFeedbackSnackbar(
            context, 'mark_action_success'.trParams({'action': action}));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showFeedbackSnackbar(context, 'error_wifi'.tr, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- THIS IS THE KEY FIX: A consistent InputDecoration helper ---
  InputDecoration _customInputDecoration(String labelText) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
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

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBar = CustomAppBar(
      useGradient: !isDarkMode,
      title: widget.isEditMode ? 'edit_mark_title'.tr : 'add_mark_title'.tr,
    );

    final bodyContent = GlassLoadingOverlay(
      isLoading: _isLoading,
      child: _errorMessage != null
          ? Center(
              child: Text(_errorMessage!,
                  style: const TextStyle(color: AppColors.error)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(scaleConfig.scale(16)),
              child: GlassCard(
                padding: EdgeInsets.all(scaleConfig.scale(24)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.isEditMode)
                        _buildReadOnlySubjectField()
                      else if (_eligibleSubjects.isEmpty)
                        _buildNoEligibleSubjectsMessage()
                      else
                        _buildSubjectDropdown(),
                      SizedBox(height: scaleConfig.scale(16)),
                      _buildMarkTextField(),
                      SizedBox(height: scaleConfig.scale(24)),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
    );

    if (isDarkMode) {
      return GradientScaffold(appBar: appBar, body: bodyContent);
    } else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        body: bodyContent,
      );
    }
  }

  Widget _buildReadOnlySubjectField() {
    return TextFormField(
      readOnly: true,
      initialValue: widget.initialSubjectName,
      decoration: _customInputDecoration('subject_label'.tr).copyWith(
        prefixIcon: Icon(
          Icons.book_outlined,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNoEligibleSubjectsMessage() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'no_eligible_subjects'.tr,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return DropdownButtonFormField<int>(
      value: _selectedSubjectId,
      onChanged: (value) => setState(() => _selectedSubjectId = value),
      items: _eligibleSubjects.map((subject) {
        return DropdownMenuItem<int>(
          value: subject['id'],
          child: Text(subject['name'], overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      decoration: _customInputDecoration('select_subject_hint'.tr),
      style: theme.textTheme.bodyLarge,
      dropdownColor: isDarkMode ? const Color(0xFF2D3748) : theme.cardColor,
      icon: Icon(Icons.keyboard_arrow_down,
          color: theme.textTheme.bodyMedium?.color),
      validator: (value) => value == null ? 'error_select_subject'.tr : null,
    );
  }

  Widget _buildMarkTextField() {
    return TextFormField(
      controller: _markController,
      decoration: _customInputDecoration('enter_mark_hint'.tr),
      style: Theme.of(context).textTheme.bodyLarge,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) return 'error_enter_mark'.tr;
        final n = int.tryParse(value);
        if (n == null) return 'error_valid_number'.tr;
        if (n < 0 || n > 100) return 'error_mark_range'.tr;
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return CustomButton(
      onPressed: _isSubmitting ? () {} : _submitForm,
      text: widget.isEditMode ? 'update_mark_button'.tr : 'save_mark_button'.tr,
      gradient: _isSubmitting
          ? AppColors.disabledGradient
          : AppColors.primaryGradient,
    );
  }
}
