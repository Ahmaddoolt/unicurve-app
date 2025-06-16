// lib/pages/student/student_curriculum_tree_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';

class SubjectNodeData {
  final int id;
  final String name;
  final String code;
  final int level;

  SubjectNodeData({
    required this.id,
    required this.name,
    required this.code,
    required this.level,
  });
}

class StudentCurriculumTreePage extends StatefulWidget {
  const StudentCurriculumTreePage({super.key});

  @override
  State<StudentCurriculumTreePage> createState() =>
      _StudentCurriculumTreePageState();
}

class _StudentCurriculumTreePageState extends State<StudentCurriculumTreePage> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;
  TreeNode<SubjectNodeData>? _rootNode;

  Map<int, String> _subjectStatusMap = {};
  Map<int, int> _subjectMarkMap = {};
  Set<int> _passedSubjectIds = {};
  List<Map<String, dynamic>> _relationships = [];
  bool _isColorByMarkView = false;

  @override
  void initState() {
    super.initState();
    _loadCurriculumData();
  }

  Future<void> _loadCurriculumData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      final studentResponse = await supabase.from('students').select('major_id').eq('user_id', userId).single();
      final majorId = studentResponse['major_id'];
      if (majorId == null) throw Exception("Student major not found");

      final responses = await Future.wait([
        supabase.from('subjects').select('id, name, code, level').eq('major_id', majorId),
        supabase.from('subject_relationships').select('source_subject_id, target_subject_id').eq('relationship_type', 'PREREQUISITE'),
        supabase.from('student_taken_subjects').select('subject_id, status, mark').eq('student_user_id', userId),
      ]);

      final subjectsResponse = responses[0] as List<dynamic>;
      final relationshipsResponse = responses[1] as List<dynamic>;
      final takenSubjectsResponse = responses[2] as List<dynamic>;

      _relationships = List<Map<String, dynamic>>.from(relationshipsResponse);
      
      final statusMap = <int, String>{};
      final markMap = <int, int>{};
      final passedSet = <int>{};
      for (var taken in takenSubjectsResponse) {
        statusMap[taken['subject_id']] = taken['status'];
        markMap[taken['subject_id']] = taken['mark'];
        if (taken['status'] == 'passed') {
          passedSet.add(taken['subject_id']);
        }
      }

      final Map<int, TreeNode<SubjectNodeData>> nodes = {};
      final Set<int> childIds = {};
      for (var subjectData in subjectsResponse) {
        final subject = SubjectNodeData(id: subjectData['id'], name: subjectData['name'] ?? 'Unnamed', code: subjectData['code'] ?? 'N/A', level: subjectData['level'] ?? 0);
        // *** FIX 1: Removed the 'key' parameter ***
        nodes[subject.id] = TreeNode<SubjectNodeData>(data: subject);
      }

      for (var rel in _relationships) {
        final parentNode = nodes[rel['source_subject_id']];
        final childNode = nodes[rel['target_subject_id']];
        if (parentNode != null && childNode != null) {
          parentNode.add(childNode);
          childIds.add(rel['target_subject_id']);
        }
      }

      // *** FIX 2: Removed the 'key' parameter ***
      final root = TreeNode<SubjectNodeData>.root();
      nodes.forEach((id, node) {
        if (!childIds.contains(id)) {
          root.add(node);
        }
      });
      
      if (root.children.isEmpty && nodes.isNotEmpty) {
         throw Exception("Curriculum structure has a cycle or is not defined correctly. No root subjects found.");
      }
      
      if (mounted) {
        setState(() {
          _subjectStatusMap = statusMap;
          _subjectMarkMap = markMap;
          _passedSubjectIds = passedSet;
          _rootNode = root;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to build curriculum tree: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        title: const Text('My Curriculum Plan'),
        centerTitle: true,
        backgroundColor: AppColors.darkBackground,
        titleTextStyle: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: scaleConfig.scaleText(18)),
        actions: [
          IconButton(
            icon: Icon(
              _isColorByMarkView ? Icons.style : Icons.style_outlined,
              color: _isColorByMarkView ? AppColors.accent : AppColors.primary,
            ),
            tooltip: 'Toggle My Progress View',
            onPressed: () => setState(() => _isColorByMarkView = !_isColorByMarkView),
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_errorMessage != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center)));
    }
    if (_rootNode == null || _rootNode!.children.isEmpty) {
      return const Center(child: Text('No curriculum plan available for your major.', style: TextStyle(color: AppColors.darkTextSecondary)));
    }

    return TreeView.simple(
      tree: _rootNode!,
      showRootNode: false,
      expansionIndicatorBuilder: (context, node) => ChevronIndicator.rightDown(tree: node, color: AppColors.darkTextSecondary, padding: const EdgeInsets.all(8)),
      builder: (BuildContext context, TreeNode<SubjectNodeData> node) {
        final subject = node.data!;
        final scaleConfig = context.scaleConfig;
        
        Color cardColor;
        Color borderColor = AppColors.primaryDark.withOpacity(0.3);
        
        final status = _subjectStatusMap[subject.id];
        final mark = _subjectMarkMap[subject.id];

        if (_isColorByMarkView) {
          if (status == 'passed') {
            cardColor = AppColors.primary.withOpacity(0.2);
            borderColor = AppColors.primary;
          } else {
            final prerequisites = _relationships
              .where((r) => r['target_subject_id'] == subject.id)
              .map<int>((r) => r['source_subject_id'] as int)
              .toSet();
            final bool prerequisitesMet = _passedSubjectIds.containsAll(prerequisites);

            if (status != 'passed' && prerequisitesMet) {
              cardColor = AppColors.accent.withOpacity(0.25);
              borderColor = AppColors.accent;
            } else {
              cardColor = AppColors.error.withOpacity(0.2);
              borderColor = AppColors.error;
            }
          }
        } else {
          cardColor = AppColors.darkBackground;
        }

        return Card(
          color: cardColor,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor, width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            title: Text(subject.name, style: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600)),
            subtitle: Text('Code: ${subject.code} | Level: ${subject.level}', style: const TextStyle(color: AppColors.darkTextSecondary)),
            trailing: _isColorByMarkView && mark != null
                ? Text(
                    '$mark%',
                    style: TextStyle(
                      color: status == 'passed' ? AppColors.primary : AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: scaleConfig.scaleText(16),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}