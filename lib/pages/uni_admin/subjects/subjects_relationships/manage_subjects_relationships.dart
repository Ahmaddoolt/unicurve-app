import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/subject.dart';
import 'subjects_list.dart';
import 'relationships_panel.dart';
import 'edit_subject_dialog.dart';

class ManageSubjectsRelationshipsPage extends StatefulWidget {
  final List<Map<String, dynamic>> subjects;
  final int? majorId;

  const ManageSubjectsRelationshipsPage({
    super.key,
    required this.subjects,
    this.majorId,
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
    _subjects = widget.subjects;
  }

  Future<void> _fetchRelationships(int subjectId) async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('subject_relationships')
          .select('target_subject_id, relationship_type')
          .eq('source_subject_id', subjectId);

      final availableSubjects = await supabase
          .from('subjects')
          .select('id, code, name')
          .neq('id', subjectId);

      if (mounted) {
        setState(() {
          _relationships =
              response
                  .map(
                    (r) => {
                      'subject_id': r['target_subject_id'].toString(),
                      'type': r['relationship_type'],
                    },
                  )
                  .toList();
          _availableSubjects =
              availableSubjects
                  .map(
                    (s) => {
                      'id': s['id'].toString(),
                      'code': s['code'],
                      'name': s['name'],
                    },
                  )
                  .toSet()
                  .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(
          'add_relations_error_fetch_relations'.trParams({
            'error': e.toString(),
          }),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSubject(int subjectId) async {
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: lighterColor,
            title: Text(
              'manage_subjects_delete_title'.tr,
              style: TextStyle(color: primaryTextColor),
            ),
            content: Text(
              'manage_subjects_delete_content'.tr,
              style: TextStyle(color: secondaryTextColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'cancel'.tr,
                  style: const TextStyle(color: AppColors.accent),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'delete_button'.tr,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await supabase
          .from('subject_professors')
          .delete()
          .eq('subject_id', subjectId);
      await supabase
          .from('subject_relationships')
          .delete()
          .or(
            'source_subject_id.eq.$subjectId,target_subject_id.eq.$subjectId',
          );
      await supabase.from('subjects').delete().eq('id', subjectId);

      if (mounted) {
        _subjects.removeWhere((s) => s['id'] == subjectId);
        if (_selectedSubject?.id == subjectId) {
          _selectedSubject = null;
          _relationships.clear();
          _availableSubjects.clear();
        }
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
      final existingRelationship =
          await supabase
              .from('subject_relationships')
              .select('id')
              .eq('source_subject_id', sourceSubjectId)
              .eq('target_subject_id', targetSubjectId)
              .eq('relationship_type', relationshipType)
              .maybeSingle();

      if (existingRelationship != null) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackbar('add_relations_error_exists'.tr);
        }
        return;
      }

      await supabase.from('subject_relationships').insert({
        'source_subject_id': sourceSubjectId,
        'target_subject_id': targetSubjectId,
        'relationship_type': relationshipType,
      });

      final response = await supabase
          .from('subject_relationships')
          .select('id')
          .eq('source_subject_id', sourceSubjectId)
          .eq('relationship_type', 'PREREQUISITE');

      final unlocksCount = response.length;
      await supabase
          .from('subjects')
          .update({'priority': unlocksCount})
          .eq('id', sourceSubjectId);

      if (mounted) {
        setState(() {
          _relationships.add({
            'subject_id': targetSubjectId,
            'type': relationshipType,
          });
          _subjects =
              _subjects.map((s) {
                if (s['id'] == sourceSubjectId) {
                  return {...s, 'priority': unlocksCount};
                }
                return s;
              }).toList();
          _isLoading = false;
        });
        showFeedbackSnackbar(
          context,
          'manage_subjects_add_relation_success'.tr,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar(
          'add_relations_error_add'.trParams({'error': e.toString()}),
        );
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
      await supabase
          .from('subject_relationships')
          .delete()
          .eq('source_subject_id', sourceSubjectId)
          .eq('target_subject_id', targetSubjectId)
          .eq('relationship_type', relationshipType);

      final response = await supabase
          .from('subject_relationships')
          .select('id')
          .eq('source_subject_id', sourceSubjectId)
          .eq('relationship_type', 'PREREQUISITE');

      final unlocksCount = response.length;
      await supabase
          .from('subjects')
          .update({'priority': unlocksCount})
          .eq('id', sourceSubjectId);

      if (mounted) {
        setState(() {
          _relationships.removeWhere(
            (r) =>
                r['subject_id'] == targetSubjectId &&
                r['type'] == relationshipType,
          );
          _subjects =
              _subjects.map((s) {
                if (s['id'] == sourceSubjectId) {
                  return {...s, 'priority': unlocksCount};
                }
                return s;
              }).toList();
          _isLoading = false;
        });
        showFeedbackSnackbar(
          context,
          'manage_subjects_remove_relation_success'.tr,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar(
          'add_relations_error_remove'.trParams({'error': e.toString()}),
        );
      }
    }
  }

  Future<void> _editSubject(Map<String, dynamic> subject) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditSubjectDialog(subject: subject),
    );

    if (result != null && mounted) {
      setState(() {
        _subjects =
            _subjects
                .map((s) => s['id'] == subject['id'] ? result : s)
                .toList();
      });
      showFeedbackSnackbar(context, 'manage_subjects_update_success'.tr);
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(
          message,
          style: const TextStyle(color: AppColors.darkTextPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: darkerColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back, color: primaryTextColor),
        ),
        centerTitle: true,
        backgroundColor: lighterColor,
        title: Text(
          'admin_manage_subjects'.tr,
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: scaleConfig.scaleText(18),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppColors.accent,
              size: scaleConfig.scale(24),
            ),
            onPressed:
                _isLoading
                    ? null
                    : () {
                      setState(() => _subjects = widget.subjects);
                    },
            tooltip: 'refresh_button_tooltip'.tr,
          ),
        ],
      ),
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: SubjectsList(
                  subjects: _subjects,
                  selectedSubject: _selectedSubject,
                  isLoading: _isLoading,
                  onSubjectTap: (subject) {
                    setState(() {
                      _selectedSubject = Subject.fromMap(subject);
                      _fetchRelationships(subject['id']);
                    });
                  },
                  onEditSubject: _editSubject,
                  onDeleteSubject: _deleteSubject,
                ),
              ),
              Expanded(
                flex: 1,
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
            Container(
              color: darkerColor,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
