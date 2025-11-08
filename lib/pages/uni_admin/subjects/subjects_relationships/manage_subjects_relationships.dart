// lib/pages/uni_admin/subjects/subjects_relationships/manage_subjects_relationships.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/domain/models/subject.dart';
import 'subjects_list.dart';
import 'relationships_panel.dart';
import '../edit_subject_dialog.dart';

class ManageSubjectsRelationshipsPage extends StatefulWidget {
  final List<Map<String, dynamic>> subjects;
  final int? majorId;
  final int universityId;

  const ManageSubjectsRelationshipsPage({
    super.key,
    required this.subjects,
    this.majorId,
    required this.universityId,
  });

  @override
  ManageSubjectsRelationshipsPageState createState() =>
      ManageSubjectsRelationshipsPageState();
}

class ManageSubjectsRelationshipsPageState
    extends State<ManageSubjectsRelationshipsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _availableSubjects = [];
  List<Map<String, dynamic>> _relationships = [];
  Subject? _selectedSubject;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _subjects = List<Map<String, dynamic>>.from(widget.subjects);
  }

  Future<void> _fetchDataForSelectedSubject(int subjectId) async {
    setState(() => _isLoading = true);
    try {
      final relationshipsResponse = await supabase
          .from('subject_relationships')
          .select('target_subject_id, relationship_type')
          .eq('source_subject_id', subjectId);

      final majorsResponse = await supabase
          .from('majors')
          .select('id')
          .eq('university_id', widget.universityId);

      if (majorsResponse.isEmpty) {
        if (mounted) setState(() => _availableSubjects.clear());
        return;
      }
      final List<int> majorIds =
          majorsResponse.map((m) => m['id'] as int).toList();

      if (majorIds.isEmpty) {
        if (mounted) setState(() => _availableSubjects.clear());
        return;
      }

      final orFilter = majorIds.map((id) => 'major_id.eq.$id').join(',');
      final availableSubjectsResponse = await supabase
          .from('subjects')
          .select('id, code, name')
          .or(orFilter)
          .neq('id', subjectId);

      if (mounted) {
        setState(() {
          _relationships = relationshipsResponse
              .map(
                (r) => {
                  'subject_id': r['target_subject_id'].toString(),
                  'type': r['relationship_type'],
                },
              )
              .toList();
          _availableSubjects = availableSubjectsResponse
              .map(
                (s) => {
                  'id': s['id'].toString(),
                  'code': s['code'],
                  'name': s['name'],
                },
              )
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(
          'add_relations_error_fetch_relations'
              .trParams({'error': e.toString()}),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSubject(int subjectId) async {
    final theme = Theme.of(context);
    final subjectToDelete = _subjects.firstWhere(
      (s) => s['id'] == subjectId,
      orElse: () => {},
    );

    if (subjectToDelete.isEmpty) {
      _showErrorSnackbar('delete_subject_error_invalid'.tr);
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
                Text('manage_subjects_delete_title'.tr,
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Text(
                    'delete_subject_confirm'
                        .trParams({'name': subjectToDelete['name']}),
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('cancel'.tr),
                    ),
                    CustomButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      text: 'delete_button'.tr,
                      backgroundColor: AppColors.error,
                      textColor: Colors.white,
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await supabase
          .from('subject_professors')
          .delete()
          .eq('subject_id', subjectId);
      await supabase.from('subject_relationships').delete().or(
          'source_subject_id.eq.$subjectId,target_subject_id.eq.$subjectId');
      await supabase.from('subjects').delete().eq('id', subjectId);

      if (mounted) {
        setState(() {
          _subjects.removeWhere((s) => s['id'] == subjectId);
          if (_selectedSubject?.id == subjectId) {
            _selectedSubject = null;
            _relationships.clear();
            _availableSubjects.clear();
          }
        });
        showFeedbackSnackbar(context, 'manage_subjects_delete_success'.tr);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(
          'manage_subjects_delete_error'.trParams({'error': e.toString()}),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addRelationship(
    int sourceSubjectId,
    String targetSubjectId,
    String relationshipType,
  ) async {
    setState(() => _isLoading = true);
    try {
      final targetIdInt = int.parse(targetSubjectId);
      final existingRelationship = await supabase
          .from('subject_relationships')
          .select('id')
          .eq('source_subject_id', sourceSubjectId)
          .eq('target_subject_id', targetIdInt)
          .eq('relationship_type', relationshipType)
          .maybeSingle();

      if (existingRelationship != null) {
        if (mounted) {
          _showErrorSnackbar('add_relations_error_exists'.tr);
        }
        return;
      }

      await supabase.from('subject_relationships').insert({
        'source_subject_id': sourceSubjectId,
        'target_subject_id': targetIdInt,
        'relationship_type': relationshipType,
      });

      final countResponse = await supabase
          .from('subject_relationships')
          .select('id')
          .eq('source_subject_id', sourceSubjectId)
          .eq('relationship_type', 'PREREQUISITE')
          .count();

      final unlocksCount = countResponse.count;
      await supabase
          .from('subjects')
          .update({'priority': unlocksCount}).eq('id', sourceSubjectId);

      if (mounted) {
        setState(() {
          _relationships.add({
            'subject_id': targetSubjectId,
            'type': relationshipType,
          });
          _subjects = _subjects.map((s) {
            if (s['id'] == sourceSubjectId) {
              return {...s, 'priority': unlocksCount};
            }
            return s;
          }).toList();
        });
        showFeedbackSnackbar(
            context, 'manage_subjects_add_relation_success'.tr);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(
          'add_relations_error_add'.trParams({'error': e.toString()}),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeRelationship(
    int sourceSubjectId,
    String targetSubjectId,
    String relationshipType,
  ) async {
    setState(() => _isLoading = true);
    try {
      final targetIdInt = int.parse(targetSubjectId);
      await supabase
          .from('subject_relationships')
          .delete()
          .eq('source_subject_id', sourceSubjectId)
          .eq('target_subject_id', targetIdInt)
          .eq('relationship_type', relationshipType);

      final countResponse = await supabase
          .from('subject_relationships')
          .select('id')
          .eq('source_subject_id', sourceSubjectId)
          .eq('relationship_type', 'PREREQUISITE')
          .count();

      final unlocksCount = countResponse.count;
      await supabase
          .from('subjects')
          .update({'priority': unlocksCount}).eq('id', sourceSubjectId);

      if (mounted) {
        setState(() {
          _relationships.removeWhere(
            (r) =>
                r['subject_id'] == targetSubjectId &&
                r['type'] == relationshipType,
          );
          _subjects = _subjects.map((s) {
            if (s['id'] == sourceSubjectId) {
              return {...s, 'priority': unlocksCount};
            }
            return s;
          }).toList();
        });
        showFeedbackSnackbar(
            context, 'manage_subjects_remove_relation_success'.tr);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(
          'add_relations_error_remove'.trParams({'error': e.toString()}),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editSubject(Map<String, dynamic> subject) async {
    if (widget.majorId == null) return;
    setState(() => _isLoading = true);
    try {
      final requirementsResponse = await supabase
          .from('major_requirements')
          .select('id, requirement_name')
          .eq('major_id', widget.majorId!);

      final requirementsMap = {
        for (var req in requirementsResponse)
          req['id'] as int: req['requirement_name'] as String,
      };

      setState(() => _isLoading = false);

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
        setState(() {
          _subjects = _subjects
              .map((s) => s['id'] == subject['id'] ? updatedSubject : s)
              .toList();
        });
        showFeedbackSnackbar(context, 'manage_subjects_update_success'.tr);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('error_loading_requirements_generic'
            .trParams({'error': e.toString()}));
      }
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    showFeedbackSnackbar(context, message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBar = CustomAppBar(
      useGradient: !isDarkMode, // Use gradient ONLY in light mode
      title: 'admin_manage_subjects'.tr,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isLoading
              ? null
              : () => setState(() => _subjects = List.from(widget.subjects)),
          tooltip: 'refresh_button_tooltip'.tr,
        ),
      ],
    );

    final bodyContent = Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2, // Give slightly more space to the subjects list
              child: SubjectsList(
                subjects: _subjects,
                selectedSubject: _selectedSubject,
                isLoading: _isLoading,
                onSubjectTap: (subject) {
                  setState(() {
                    _selectedSubject = Subject.fromMap(subject);
                    _fetchDataForSelectedSubject(subject['id']);
                  });
                },
                onEditSubject: (subject) => _editSubject(subject),
                onDeleteSubject: (subjectId) => _deleteSubject(subjectId),
              ),
            ),
            Expanded(
              flex: 3, // Give more space to the relationships panel
              child: RelationshipsPanel(
                selectedSubject: _selectedSubject,
                relationships: _relationships,
                availableSubjects: _availableSubjects,
                isLoading: _isLoading,
                onAddRelationship: _addRelationship,
                onRemoveRelationship: _removeRelationship,
              ),
            ),
          ],
        ),
        if (_isLoading)
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withOpacity(0.1),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
          ),
      ],
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
}
