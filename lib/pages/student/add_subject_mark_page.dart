// lib/pages/student/add_subject_mark_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';

class AddSubjectMarkPage extends StatefulWidget {
  final List<Map<String, dynamic>> takenSubjects;
  final bool isEditMode;
  final int? recordId;
  final int? initialSubjectId;
  final String? initialSubjectName;
  final int? initialMark;

  const AddSubjectMarkPage({
    super.key,
    required this.takenSubjects,
    this.isEditMode = false,
    this.recordId,
    this.initialSubjectId,
    this.initialSubjectName,
    this.initialMark,
  });

  @override
  State<AddSubjectMarkPage> createState() => _AddSubjectMarkPageState();
}

class _AddSubjectMarkPageState extends State<AddSubjectMarkPage> {
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
      setState(() { _isLoading = false; });
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
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in.');

      final studentRes = await supabase.from('students').select('major_id').eq('user_id', userId).single();
      final majorId = studentRes['major_id'];
      if (majorId == null) throw Exception('Student not assigned to a major.');

      final allSubjectsRes = await supabase.from('subjects').select('id, name, code').eq('major_id', majorId);
      final List<Map<String, dynamic>> allSubjects = List.from(allSubjectsRes);

      final relationshipsRes = await supabase.from('subject_relationships').select('source_subject_id, target_subject_id').eq('relationship_type', 'PREREQUISITE'); // Using PREREQUISITE as it's the standard
      final List<Map<String, dynamic>> relationships = List.from(relationshipsRes);
      
      // --- FIX IS HERE: Changed 'subjects' (plural) to 'subject' (singular) ---
      final passedSubjectIds = widget.takenSubjects
          .where((s) => s['status'] == 'passed')
          .map<int>((s) => s['subject']['id'] as int) 
          .toSet();
      
      // --- FIX IS HERE: Changed 'subjects' (plural) to 'subject' (singular) ---
      final takenSubjectIds = widget.takenSubjects
          .map<int>((s) => s['subject']['id'] as int)
          .toSet();

      List<Map<String, dynamic>> eligible = [];
      for (var subject in allSubjects) {
        final subjectId = subject['id'];
        if (takenSubjectIds.contains(subjectId)) {
          continue;
        }
        final prerequisites = relationships
            .where((r) => r['target_subject_id'] == subjectId)
            .map<int>((r) => r['source_subject_id'] as int)
            .toSet();
            
        if (passedSubjectIds.containsAll(prerequisites)) {
          eligible.add(subject);
        }
      }
      if (mounted) {
        setState(() { _eligibleSubjects = eligible; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _errorMessage = "Failed to load subjects: ${e.toString()}"; });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      final mark = int.parse(_markController.text);
      final status = mark >= 50 ? 'passed' : 'failed';

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
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mark ${widget.isEditMode ? 'updated' : 'added'} successfully!'), backgroundColor: AppColors.primary),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
       if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
        );
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        title: Text(
          widget.isEditMode ? 'Edit Mark' : 'Add a Subject Mark',
          style: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: scaleConfig.scaleText(18)),
        ),
        backgroundColor: AppColors.darkBackground,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.all(scaleConfig.scale(16)),
                    children: [
                      if (widget.isEditMode)
                        TextFormField(
                          readOnly: true,
                          initialValue: widget.initialSubjectName,
                          decoration: _inputDecoration('Subject').copyWith(
                            prefixIcon: const Icon(Icons.book, color: AppColors.darkTextSecondary),
                          ),
                          style: const TextStyle(color: AppColors.darkTextSecondary),
                        )
                      else if (_eligibleSubjects.isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("No eligible subjects to add at this time.", style: TextStyle(color: AppColors.darkTextSecondary)),
                        ))
                      else
                        DropdownButtonFormField<int>(
                          value: _selectedSubjectId,
                          onChanged: (value) => setState(() => _selectedSubjectId = value),
                          items: _eligibleSubjects.map((subject) => DropdownMenuItem<int>(value: subject['id'], child: Text(subject['name']))).toList(),
                          decoration: _inputDecoration('Select Subject'),
                          style: const TextStyle(color: AppColors.darkTextPrimary),
                          dropdownColor: AppColors.darkBackground,
                          validator: (value) => value == null ? 'Please select a subject' : null,
                        ),

                      SizedBox(height: scaleConfig.scale(16)),
                      
                      TextFormField(
                        controller: _markController,
                        decoration: _inputDecoration('Enter Mark (0-100)'),
                        style: const TextStyle(color: AppColors.darkTextPrimary),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter a mark';
                          final n = int.tryParse(value);
                          if (n == null) return 'Please enter a valid number';
                          if (n < 0 || n > 100) return 'Mark must be between 0 and 100';
                          return null;
                        },
                      ),

                      SizedBox(height: scaleConfig.scale(24)),
                      
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(14)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          widget.isEditMode ? 'Update Mark' : 'Save Mark',
                          style: TextStyle(fontSize: scaleConfig.scaleText(16), color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
      filled: true,
      fillColor: AppColors.darkBackground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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