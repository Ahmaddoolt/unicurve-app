import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/student/subjects/student_curriculum_tree_page.dart';

class ProfessorStatus {
  final String name;
  final bool isActive;

  ProfessorStatus({required this.name, required this.isActive});
}

enum SubjectSortOrder { byPriority, byLevel, byName, byCode }

class StudentSubjectsPage extends StatefulWidget {
  const StudentSubjectsPage({super.key});

  @override
  StudentSubjectsPageState createState() => StudentSubjectsPageState();
}

class StudentSubjectsPageState extends State<StudentSubjectsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _filteredSubjects = [];
  Map<int, String> _requirementsMap = {};

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _majorName;
  String? _errorMessage;

  SubjectSortOrder _currentSortOrder = SubjectSortOrder.byPriority;

  @override
  void initState() {
    super.initState();
    _fetchStudentMajorAndSubjects();
    _searchController.addListener(_filterSubjects);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentMajorAndSubjects() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('error_user_not_logged_in'.tr);

      final studentResponse =
          await supabase
              .from('students')
              .select('major_id, majors(name)')
              .eq('user_id', userId)
              .single();

      final majorId = studentResponse['major_id'];
      if (majorId == null) throw Exception('error_not_in_major'.tr);

      final majorData = studentResponse['majors'];
      final majorName =
          majorData?['name'] as String? ?? 'your_major_fallback'.tr;

      final results = await Future.wait([
        supabase
            .from('subjects')
            .select('*, subject_professors(isActive, professors(name))')
            .eq('major_id', majorId),
        supabase
            .from('major_requirements')
            .select('id, requirement_name')
            .eq('major_id', majorId),
      ]);

      final subjectsResponse = results[0] as List<dynamic>;
      final requirementsResponse = results[1] as List<dynamic>;

      final requirementsMap = {
        for (var req in requirementsResponse)
          (req['id'] as int): req['requirement_name'] as String,
      };

      final List<Map<String, dynamic>> processedSubjects = [];
      for (var subjectData in subjectsResponse) {
        final subjectMap = Map<String, dynamic>.from(subjectData);
        final rawProfessors = subjectMap['subject_professors'] as List<dynamic>;
        final List<ProfessorStatus> professors = [];
        for (final record in rawProfessors) {
          final professorData = record['professors'];
          if (professorData != null && professorData['name'] != null) {
            professors.add(
              ProfessorStatus(
                name: professorData['name'] as String,
                isActive: record['isActive'] as bool? ?? false,
              ),
            );
          }
        }
        professors.sort((a, b) {
          if (a.isActive && !b.isActive) return -1;
          if (!a.isActive && b.isActive) return 1;
          return a.name.compareTo(b.name);
        });
        subjectMap['professors'] = professors;
        processedSubjects.add(subjectMap);
      }

      if (mounted) {
        setState(() {
          _majorName = majorName;
          _subjects = processedSubjects;
          _requirementsMap = requirementsMap;
          _isLoading = false;
        });
        _applySortAndFilter();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'error_wifi'.tr;
          showFeedbackSnackbar(context, _errorMessage!, isError: true);
        });
      }
    }
  }

  void _sortSubjects() {
    _subjects.sort((a, b) {
      switch (_currentSortOrder) {
        case SubjectSortOrder.byPriority:
          final priorityA = a['priority'] as int? ?? -1;
          final priorityB = b['priority'] as int? ?? -1;
          return priorityB.compareTo(priorityA);
        case SubjectSortOrder.byLevel:
          final levelA = a['level'] as int? ?? 999;
          final levelB = b['level'] as int? ?? 999;
          return levelA.compareTo(levelB);
        case SubjectSortOrder.byCode:
          final codeA = a['code']?.toString() ?? '';
          final codeB = b['code']?.toString() ?? '';
          return codeA.compareTo(codeB);
        case SubjectSortOrder.byName:
          final nameA = a['name']?.toString() ?? '';
          final nameB = b['name']?.toString() ?? '';
          return nameA.compareTo(nameB);
      }
    });
  }

  void _applySortAndFilter() {
    _sortSubjects();
    _filterSubjects();
  }

  void _filterSubjects() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSubjects =
          query.isEmpty
              ? List.from(_subjects)
              : _subjects.where((subject) {
                final name = subject['name']?.toString().toLowerCase() ?? '';
                final code = subject['code']?.toString().toLowerCase() ?? '';
                final typeName =
                    _requirementsMap[subject['type']]?.toLowerCase() ?? '';
                final professors =
                    subject['professors'] as List<ProfessorStatus>;
                final hasProfessorMatch = professors.any(
                  (p) => p.name.toLowerCase().contains(query),
                );
                return name.contains(query) ||
                    code.contains(query) ||
                    typeName.contains(query) ||
                    hasProfessorMatch;
              }).toList();
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'sort_by_title'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              _buildSortOption(
                title: 'priority_label'.tr,
                icon: Icons.star_border,
                order: SubjectSortOrder.byPriority,
              ),
              _buildSortOption(
                title: 'level_label'.tr,
                icon: Icons.layers_outlined,
                order: SubjectSortOrder.byLevel,
              ),
              _buildSortOption(
                title: 'subject_name_label'.tr,
                icon: Icons.sort_by_alpha,
                order: SubjectSortOrder.byName,
              ),
              _buildSortOption(
                title: 'subject_code_label'.tr,
                icon: Icons.pin_outlined,
                order: SubjectSortOrder.byCode,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption({
    required String title,
    required IconData icon,
    required SubjectSortOrder order,
  }) {
    final bool isSelected = _currentSortOrder == order;
    return ListTile(
      leading: Icon(
        icon,
        color:
            isSelected ? AppColors.primary : Theme.of(context).iconTheme.color,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color:
              isSelected
                  ? AppColors.primary
                  : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing:
          isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          setState(() => _currentSortOrder = order);
          _applySortAndFilter();
        }
      },
    );
  }

  void _showSubjectDetailsDialog(Map<String, dynamic> subject) {
    final scaleConfig = context.scaleConfig;
    final String typeName =
        _requirementsMap[subject['type']] ?? 'uncategorized_label'.tr;
    final List<ProfessorStatus> professors = subject['professors'] ?? [];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(scaleConfig.scale(16)),
              side: const BorderSide(color: AppColors.primaryDark, width: 1.5),
            ),
            title: Center(
              child: Text(
                subject['name']?.toString() ?? 'subject_details_title'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: scaleConfig.scaleText(20),
                ),
              ),
            ),
            contentPadding: EdgeInsets.all(scaleConfig.scale(16)),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  _buildDetailRow(
                    icon: Icons.tag,
                    label: 'code_label'.tr,
                    value: Text(
                      subject['code']?.toString() ?? 'not_available'.tr,
                      style: _valueTextStyle(scaleConfig),
                    ),
                  ),
                  _buildDetailRow(
                    icon: Icons.schedule,
                    label: 'hours_label'.tr.replaceAll('@hours ', ''),
                    value: Text(
                      'hours_label'.trParams({
                        'hours': subject['hours']?.toString() ?? '0',
                      }),
                      style: _valueTextStyle(scaleConfig),
                    ),
                  ),
                  _buildDetailRow(
                    icon: Icons.bar_chart,
                    label: 'level_label'.tr,
                    value: Text(
                      subject['level']?.toString() ?? 'not_available'.tr,
                      style: _valueTextStyle(scaleConfig),
                    ),
                  ),
                  _buildDetailRow(
                    icon: Icons.category_outlined,
                    label: 'type_label'.tr,
                    value: Text(typeName, style: _valueTextStyle(scaleConfig)),
                  ),
                  _buildDetailRow(
                    icon: Icons.how_to_reg_outlined,
                    label: 'open_for_reg_label'.tr,
                    value: Text(
                      subject['is_open'] == true ? 'yes'.tr : 'no'.tr,
                      style: _valueTextStyle(
                        scaleConfig,
                        color:
                            subject['is_open'] == true
                                ? AppColors.primary
                                : AppColors.error,
                      ),
                    ),
                  ),
                  _buildProfessorSection(
                    professors: professors,
                    scaleConfig: scaleConfig,
                  ),
                  _buildDetailRow(
                    icon: Icons.description_outlined,
                    label: 'description_label'.tr,
                    value: Text(
                      subject['description']?.toString() ??
                          'no_description_provided'.tr,
                      style: _valueTextStyle(scaleConfig),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'close_button'.tr,
                  style: const TextStyle(color: AppColors.accent),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildProfessorSection({
    required List<ProfessorStatus> professors,
    required ScaleConfig scaleConfig,
  }) {
    if (professors.isEmpty) {
      return _buildDetailRow(
        icon: Icons.school_outlined,
        label: 'professors_label'.tr,
        value: Text(
          'no_professors_listed'.tr,
          style: _valueTextStyle(scaleConfig),
        ),
      );
    }
    return _buildDetailRow(
      icon: Icons.school_outlined,
      label: 'professors_label'.tr,
      value: RichText(
        text: TextSpan(
          style: _valueTextStyle(scaleConfig),
          children:
              professors.map((prof) {
                return TextSpan(
                  text: '${prof.name}\n',
                  style: TextStyle(
                    color:
                        prof.isActive
                            ? AppColors.accent
                            : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight:
                        prof.isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required Widget value,
    IconData? icon,
    Color? iconColor,
  }) {
    final scaleConfig = context.scaleConfig;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(6)),
      child: Card(
        color: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        ),
        elevation: 0,
        child: ListTile(
          leading: Icon(
            icon ?? Icons.label_important_outline,
            color: iconColor ?? AppColors.primary,
            size: scaleConfig.scale(22),
          ),
          title: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: scaleConfig.scaleText(14),
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: value,
        ),
      ),
    );
  }

  TextStyle _valueTextStyle(ScaleConfig scaleConfig, {Color? color}) {
    return TextStyle(
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
      fontSize: scaleConfig.scaleText(15),
      fontWeight: FontWeight.w600,
    );
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
        backgroundColor: darkerColor,
        title: Text(
          _majorName != null
              ? 'major_subjects_title'.trParams({'majorName': _majorName!})
              : 'my_subjects_title'.tr,
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: scaleConfig.scaleText(18),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.sort,
              color: AppColors.primary,
              size: scaleConfig.scale(24),
            ),
            tooltip: 'sort_subjects_tooltip'.tr,
            onPressed: _isLoading ? null : _showSortOptions,
          ),
          IconButton(
            icon: Icon(
              Icons.account_tree_outlined,
              color: AppColors.primary,
              size: scaleConfig.scale(22),
            ),
            tooltip: 'view_curriculum_plan_tooltip'.tr,
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentCurriculumTreePage(),
                  ),
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(scaleConfig.scale(16)),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search_subjects_hint'.tr,
                hintStyle: TextStyle(color: secondaryTextColor, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: darkerColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: primaryTextColor),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                    : _errorMessage != null
                    ? Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _fetchStudentMajorAndSubjects,
                      color: AppColors.primary,
                      backgroundColor: darkerColor,
                      child:
                          _filteredSubjects.isEmpty
                              ? Center(
                                child: Text(
                                  _searchController.text.isEmpty
                                      ? 'no_subjects_found'.tr
                                      : 'no_subjects_match_search'.tr,
                                  style: TextStyle(color: secondaryTextColor),
                                  textAlign: TextAlign.center,
                                ),
                              )
                              : ListView.builder(
                                padding: EdgeInsets.symmetric(
                                  horizontal: scaleConfig.scale(8),
                                ),
                                itemCount: _filteredSubjects.length,
                                itemBuilder: (context, index) {
                                  final subject = _filteredSubjects[index];
                                  return Card(
                                    color: darkerColor,
                                    margin: EdgeInsets.symmetric(
                                      vertical: scaleConfig.scale(4),
                                      horizontal: scaleConfig.scale(8),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      side: const BorderSide(
                                        color: AppColors.primary,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        subject['name'] ??
                                            'no_name_fallback'.tr,
                                        style: TextStyle(
                                          color: primaryTextColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        subject['code'] ??
                                            'no_code_fallback'.tr,
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.chevron_right,
                                        color: AppColors.primary,
                                      ),
                                      onTap:
                                          () => _showSubjectDetailsDialog(
                                            subject,
                                          ),
                                    ),
                                  );
                                },
                              ),
                    ),
          ),
        ],
      ),
    );
  }
}
