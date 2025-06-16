import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
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
        setState(() => _isLoading = false);
        _showSnackBar('Error fetching relationships: $e', isError: true);
      }
    }
  }

  Future<void> _deleteSubject(int subjectId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.darkSurface,
            title: const Text(
              'Confirm Deletion',
              style: TextStyle(color: AppColors.darkTextPrimary),
            ),
            content: const Text(
              'Are you sure you want to delete this subject? This will also remove it from all professors and clear any prerequisite relationships. This action cannot be undone.',
              style: TextStyle(color: AppColors.darkTextSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.accent),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) {
      return;
    }

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
        _showSnackBar('Subject deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error deleting subject: $e', isError: true);
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
          _showSnackBar('This relationship already exists', isError: true);
        }
        return;
      }

      await supabase.from('subject_relationships').insert({
        'source_subject_id': sourceSubjectId,
        'target_subject_id': targetSubjectId,
        'relationship_type': relationshipType,
      });

      // --- MODIFIED LOGIC ---
      final response = await supabase
          .from('subject_relationships')
          .select('id')
          .eq('source_subject_id', sourceSubjectId)
          .eq('relationship_type', 'PREREQUISITE'); // Changed from 'UNLOCKS'

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
        _showSnackBar('Relationship added successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error adding relationship: $e', isError: true);
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

      // --- MODIFIED LOGIC ---
      final response = await supabase
          .from('subject_relationships')
          .select('id')
          .eq('source_subject_id', sourceSubjectId)
          .eq('relationship_type', 'PREREQUISITE'); // Changed from 'UNLOCKS'

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
        _showSnackBar('Relationship removed successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error removing relationship: $e', isError: true);
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
      _showSnackBar('Subject updated successfully');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.darkTextPrimary),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primaryDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Manage Subjects',
          style: TextStyle(
            color: AppColors.darkTextPrimary,
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
                      setState(() {
                        _subjects = widget.subjects;
                      });
                    },
            tooltip: 'Refresh',
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
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}