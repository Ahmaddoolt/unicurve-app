import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/glass_loading_overlay.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('error_user_not_logged_in'.tr);

      final studentResponse = await supabase
          .from('students')
          .select('major_id')
          .eq('user_id', userId)
          .single();
      final majorId = studentResponse['major_id'];
      if (majorId == null) throw Exception('error_student_major_not_found'.tr);

      final responses = await Future.wait([
        supabase
            .from('subjects')
            .select('id, name, code, level')
            .eq('major_id', majorId),
        supabase
            .from('subject_relationships')
            .select('source_subject_id, target_subject_id')
            .eq('relationship_type', 'PREREQUISITE'),
        supabase
            .from('student_taken_subjects')
            .select('subject_id, status, mark')
            .eq('student_user_id', userId),
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
        final subject = SubjectNodeData(
          id: subjectData['id'],
          name: subjectData['name'] ?? 'unnamed_fallback'.tr,
          code: subjectData['code'] ?? 'not_available'.tr,
          level: subjectData['level'] ?? 0,
        );
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

      final root = TreeNode<SubjectNodeData>.root();
      nodes.forEach((id, node) {
        if (!childIds.contains(id)) {
          root.add(node);
        }
      });

      if (root.children.isEmpty && nodes.isNotEmpty) {
        throw Exception('error_curriculum_cycle'.tr);
      }

      if (mounted) {
        setState(() {
          _subjectStatusMap = statusMap;
          _subjectMarkMap = markMap;
          _passedSubjectIds = passedSet;
          _rootNode = root;
        });
      }
    } catch (e) {
      if (mounted) {
        _errorMessage =
            'error_build_curriculum_tree'.trParams({'error': e.toString()});
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBar = CustomAppBar(
      useGradient: !isDarkMode,
      title: 'my_curriculum_plan_title'.tr,
      actions: [
        IconButton(
          icon: Icon(
            _isColorByMarkView ? Icons.style : Icons.style_outlined,
          ),
          tooltip: 'toggle_progress_view_tooltip'.tr,
          onPressed: () =>
              setState(() => _isColorByMarkView = !_isColorByMarkView),
        ),
      ],
    );

    final bodyContent = GlassLoadingOverlay(
      isLoading: _isLoading,
      child: _buildBody(context),
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

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_rootNode == null || _rootNode!.children.isEmpty) {
      return _isLoading
          ? const SizedBox.shrink()
          : Center(
              child: Text(
                'no_curriculum_plan_available'.tr,
                style: theme.textTheme.bodyMedium,
              ),
            );
    }

    return TreeView.simple(
      tree: _rootNode!,
      showRootNode: false,
      expansionIndicatorBuilder: (context, node) => ChevronIndicator.rightDown(
        tree: node,
        color: theme.textTheme.bodyMedium?.color,
        padding: const EdgeInsets.all(8),
      ),
      indentation: const Indentation(width: 20),
      builder: (BuildContext context, TreeNode<SubjectNodeData> node) {
        final subject = node.data!;
        final scaleConfig = context.scaleConfig;

        Color? statusColor;
        final status = _subjectStatusMap[subject.id];
        final mark = _subjectMarkMap[subject.id];

        if (_isColorByMarkView) {
          if (status == 'passed') {
            statusColor = AppColors.primary; // Passed
          } else {
            final prerequisites = _relationships
                .where((r) => r['target_subject_id'] == subject.id)
                .map<int>((r) => r['source_subject_id'] as int)
                .toSet();
            final bool prerequisitesMet =
                _passedSubjectIds.containsAll(prerequisites);

            if (prerequisitesMet) {
              statusColor = AppColors.accent; // Available to take
            } else {
              statusColor = AppColors.error; // Locked
            }
          }
        }

        // --- THE KEY FIX IS HERE ---
        return GlassCard(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          borderColor: statusColor, // Pass the calculated color to the border
          child: ListTile(
            title: Text(
              subject.name,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'subject_code_level'.trParams(
                  {'code': subject.code, 'level': subject.level.toString()}),
              style: theme.textTheme.bodyMedium,
            ),
            trailing: _isColorByMarkView && mark != null
                ? Text(
                    '$mark%',
                    style: TextStyle(
                      color: status == 'passed'
                          ? AppColors.primary
                          : AppColors.error,
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
