import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
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
  String? _errorMessage;
  int? _selectedSubjectId;

  List<Map<String, dynamic>> _eligibleSubjects = [];

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _selectedSubjectId = widget.initialSubjectId;
      _markController.text = widget.initialMark.toString();
      setState(() {
        _isLoading = false;
      });
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in.');

      final studentRes =
          await supabase
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
      final List<Map<String, dynamic>> relationships = List.from(
        relationshipsRes,
      );

      final passedSubjectIds =
          widget.takenSubjects
              .where((s) => s['status'] == 'passed' && s['subjects'] != null)
              .map<int>((s) => s['subjects']['id'] as int)
              .toSet();

      final takenSubjectIds =
          widget.takenSubjects
              .where((s) => s['subjects'] != null)
              .map<int>((s) => s['subjects']['id'] as int)
              .toSet();

      List<Map<String, dynamic>> eligible = [];
      for (var subject in allSubjects) {
        final subjectId = subject['id'];
        if (takenSubjectIds.contains(subjectId)) {
          continue;
        }
        final prerequisites =
            relationships
                .where((r) => r['target_subject_id'] == subjectId)
                .map<int>((r) => r['source_subject_id'] as int)
                .toSet();
        if (passedSubjectIds.containsAll(prerequisites)) {
          eligible.add(subject);
        }
      }

      if (mounted) {
        setState(() {
          _eligibleSubjects = eligible;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'error_load_subjects'.tr;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final mark = int.parse(_markController.text);

      final int passMark = widget.universityType == 'Public' ? 60 : 50;
      final status = mark >= passMark ? 'passed' : 'failed';

      if (widget.isEditMode) {
        await supabase
            .from('student_taken_subjects')
            .update({'mark': mark, 'status': status})
            .eq('id', widget.recordId!);
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
          context,
          'mark_action_success'.trParams({'action': action}),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showFeedbackSnackbar(context, 'error_wifi'.tr);
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: lighterColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.isEditMode ? 'edit_mark_title'.tr : 'add_mark_title'.tr,
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: scaleConfig.scaleText(18),
          ),
        ),
        backgroundColor: darkerColor,
        iconTheme: IconThemeData(color: primaryTextColor),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
              : _errorMessage != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(scaleConfig.scale(16)),
                  children: [
                    if (widget.isEditMode)
                      TextFormField(
                        readOnly: true,
                        initialValue: widget.initialSubjectName,
                        decoration: _inputDecoration(
                          'subject_label'.tr,
                        ).copyWith(
                          prefixIcon: Icon(
                            Icons.book_outlined,
                            color: secondaryTextColor,
                          ),
                        ),
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (_eligibleSubjects.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'no_eligible_subjects'.tr,
                            style: TextStyle(color: secondaryTextColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: _selectedSubjectId,
                        onChanged:
                            (value) =>
                                setState(() => _selectedSubjectId = value),
                        items:
                            _eligibleSubjects.map((subject) {
                              return DropdownMenuItem<int>(
                                value: subject['id'],
                                child: Text(
                                  subject['name'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                        decoration: _inputDecoration('select_subject_hint'.tr),
                        style: TextStyle(color: primaryTextColor),
                        dropdownColor: darkerColor,
                        validator:
                            (value) =>
                                value == null
                                    ? 'error_select_subject'.tr
                                    : null,
                      ),
                    SizedBox(height: scaleConfig.scale(16)),
                    TextFormField(
                      controller: _markController,
                      decoration: _inputDecoration('enter_mark_hint'.tr),
                      style: TextStyle(color: primaryTextColor),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'error_enter_mark'.tr;
                        }
                        final n = int.tryParse(value);
                        if (n == null) return 'error_valid_number'.tr;
                        if (n < 0 || n > 100) {
                          return 'error_mark_range'.tr;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: scaleConfig.scale(24)),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          vertical: scaleConfig.scale(14),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        widget.isEditMode
                            ? 'update_mark_button'.tr
                            : 'save_mark_button'.tr,
                        style: TextStyle(
                          fontSize: scaleConfig.scaleText(16),
                          color: primaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: secondaryTextColor),
      filled: true,
      fillColor: darkerColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
