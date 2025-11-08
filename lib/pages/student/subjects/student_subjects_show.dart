// lib/pages/student/subjects/student_subjects_show.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/glass_loading_overlay.dart';
import 'package:unicurve/core/utils/gradient_icon.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
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
  final List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _filteredSubjects = [];
  Map<int, String> _requirementsMap = {};

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  String? _majorName;
  String? _errorMessage;
  int? _majorId;

  // --- PAGINATION STATE ---
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const _pageSize = 20; // Fetch 20 subjects at a time

  SubjectSortOrder _currentSortOrder = SubjectSortOrder.byPriority;

  @override
  void initState() {
    super.initState();
    _fetchStudentMajorAndSubjects(isRefresh: true);
    _searchController.addListener(_filterSubjects);
    _scrollController.addListener(_onScroll); // Listener for pagination
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // --- PAGINATION: This triggers fetching the next page. ---
  void _onScroll() {
    if (!_isLoading &&
        !_isLoadingMore &&
        _hasMore &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300) {
      _fetchStudentMajorAndSubjects();
    }
  }

  // --- PAGINATION: This method is now adapted for pagination ---
  Future<void> _fetchStudentMajorAndSubjects({bool isRefresh = false}) async {
    if (!mounted || (isRefresh == false && _isLoadingMore)) return;

    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _subjects.clear();
        _filteredSubjects.clear();
        _hasMore = true;
        _errorMessage = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      if (_majorId == null) {
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) throw Exception('error_user_not_logged_in'.tr);

        final studentResponse = await supabase
            .from('students')
            .select('major_id, majors(name)')
            .eq('user_id', userId)
            .single();

        _majorId = studentResponse['major_id'];
        if (_majorId == null) throw Exception('error_not_in_major'.tr);

        final majorData = studentResponse['majors'];
        _majorName =
            majorData?['name'] as String? ?? 'your_major_fallback'.tr;
      }

      if (isRefresh) {
        final requirementsResponse = await supabase
            .from('major_requirements')
            .select('id, requirement_name')
            .eq('major_id', _majorId!);
        _requirementsMap = {
          for (var req in requirementsResponse)
            (req['id'] as int): req['requirement_name'] as String,
        };
      }

      // --- PAGINATION: Calculate range for Supabase query ---
      final from = _currentPage * _pageSize;
      final to = from + _pageSize - 1;

      PostgrestTransformBuilder<PostgrestList> query = supabase
          .from('subjects')
          .select('*, subject_professors(isActive, professors(name))')
          .eq('major_id', _majorId!);

      switch (_currentSortOrder) {
        case SubjectSortOrder.byPriority:
          query = query.order('priority', ascending: false, nullsFirst: false);
          break;
        case SubjectSortOrder.byLevel:
          query = query.order('level', ascending: true);
          break;
        case SubjectSortOrder.byCode:
          query = query.order('code', ascending: true);
          break;
        case SubjectSortOrder.byName:
          query = query.order('name', ascending: true);
          break;
      }

      // --- PAGINATION: Apply the range to the query ---
      final subjectsResponse = await query.range(from, to);

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
          _subjects.addAll(processedSubjects); // Append new subjects
          _hasMore = processedSubjects.length == _pageSize; // Check if more exist
          _currentPage++; // Increment page for next fetch
          _filterSubjects();
        });
      }
    } catch (e) {
      if (mounted) {
        _errorMessage = 'error_wifi'.tr;
        showFeedbackSnackbar(context, _errorMessage!, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _applySortAndFilter() {
    _fetchStudentMajorAndSubjects(isRefresh: true);
  }

  void _filterSubjects() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSubjects = _subjects.where((subject) {
        final name = subject['name']?.toString().toLowerCase() ?? '';
        final code = subject['code']?.toString().toLowerCase() ?? '';
        final typeName =
            _requirementsMap[subject['type']]?.toLowerCase() ?? '';
        final professors = subject['professors'] as List<ProfessorStatus>;
        final hasProfessorMatch =
            professors.any((p) => p.name.toLowerCase().contains(query));
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassCard(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('sort_by_title'.tr,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _buildSortOption(
                    title: 'priority_label'.tr,
                    icon: Icons.star_border,
                    order: SubjectSortOrder.byPriority),
                _buildSortOption(
                    title: 'level_label'.tr,
                    icon: Icons.layers_outlined,
                    order: SubjectSortOrder.byLevel),
                _buildSortOption(
                    title: 'subject_name_label'.tr,
                    icon: Icons.sort_by_alpha,
                    order: SubjectSortOrder.byName),
                _buildSortOption(
                    title: 'subject_code_label'.tr,
                    icon: Icons.pin_outlined,
                    order: SubjectSortOrder.byCode),
              ],
            ),
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
          color: isSelected
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
    final theme = Theme.of(context);
    final String typeName =
        _requirementsMap[subject['type']] ?? 'uncategorized_label'.tr;
    final List<ProfessorStatus> professors = subject['professors'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: GlassCard(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: scaleConfig.widthPercentage(0.8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subject['name']?.toString() ?? 'subject_details_title'.tr,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDetailRow(
                              label: 'code_label'.tr,
                              value: subject['code']?.toString() ?? 'N/A',
                              icon: Icons.tag),
                          _buildDetailRow(
                              label: 'hours_label'.tr.replaceAll('@hours ', ''),
                              value: 'hours_label'.trParams({
                                'hours': subject['hours']?.toString() ?? '0'
                              }),
                              icon: Icons.schedule),
                          _buildDetailRow(
                              label: 'level_label'.tr,
                              value: subject['level']?.toString() ?? 'N/A',
                              icon: Icons.bar_chart),
                          _buildDetailRow(
                              label: 'type_label'.tr,
                              value: typeName,
                              icon: Icons.category_outlined),
                          _buildDetailRow(
                              label: 'open_for_reg_label'.tr,
                              value: subject['is_open'] == true
                                  ? 'yes'.tr
                                  : 'no'.tr,
                              icon: subject['is_open'] == true
                                  ? Icons.check_circle_outline
                                  : Icons.highlight_off,
                              iconColor: subject['is_open'] == true
                                  ? AppColors.primary
                                  : AppColors.error),
                          _buildProfessorSection(
                              professors: professors, scaleConfig: scaleConfig),
                          _buildDetailRow(
                              label: 'description_label'.tr,
                              value: subject['description']?.toString() ??
                                  'no_description_provided'.tr,
                              icon: Icons.description_outlined),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CustomButton(
                      onPressed: () => Navigator.pop(context),
                      text: 'close_button'.tr,
                      gradient: AppColors.primaryGradient,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
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
        valueWidget: Text('no_professors_listed'.tr,
            style: _valueTextStyle(scaleConfig)),
      );
    }
    return _buildDetailRow(
      icon: Icons.school_outlined,
      label: 'professors_label'.tr,
      valueWidget: RichText(
        text: TextSpan(
          style: _valueTextStyle(scaleConfig,
              color: Theme.of(context).textTheme.bodyMedium?.color),
          children: professors.map((prof) {
            return TextSpan(
              text: '${prof.name}${prof.isActive ? " (Teaching)" : ""}\n',
              style: TextStyle(
                color: prof.isActive
                    ? AppColors.accent
                    : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: prof.isActive ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    String? value,
    Widget? valueWidget,
    IconData? icon,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.label_important_outline,
              color: iconColor ?? AppColors.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                valueWidget ??
                    Text(value ?? '',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBar = CustomAppBar(
      useGradient: !isDarkMode,
      title: _majorName != null
          ? 'major_subjects_title'.trParams({'majorName': _majorName!})
          : 'my_subjects_title'.tr,
      actions: [
        IconButton(
          icon: const Icon(Icons.sort),
          tooltip: 'sort_subjects_tooltip'.tr,
          onPressed: _isLoading ? null : _showSortOptions,
        ),
        IconButton(
          icon: const Icon(Icons.account_tree_outlined),
          tooltip: 'view_curriculum_plan_tooltip'.tr,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentCurriculumTreePage(),
            ),
          ),
        ),
      ],
    );

    final bodyContent = GlassLoadingOverlay(
      isLoading: _isLoading && _subjects.isEmpty,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(scaleConfig.scale(16),
                scaleConfig.scale(16), scaleConfig.scale(16), 0),
            child: isDarkMode
                ? GlassCard(
                    child: _buildSearchField(theme),
                    borderRadius: BorderRadius.circular(12))
                : _buildSearchField(theme),
          ),
          Expanded(
            child: _errorMessage != null
                ? Center(
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: AppColors.error)))
                : RefreshIndicator(
                    onRefresh: () =>
                        _fetchStudentMajorAndSubjects(isRefresh: true),
                    color: AppColors.primary,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    child: _filteredSubjects.isEmpty && !_isLoading
                        ? Center(
                            child: Text(
                              _subjects.isEmpty
                                  ? 'no_subjects_found'.tr
                                  : 'no_subjects_match_search'.tr,
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(scaleConfig.scale(12)),
                            // --- PAGINATION: Adjust item count for loading indicator ---
                            itemCount:
                                _filteredSubjects.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              // --- PAGINATION: Show loading indicator at the end ---
                              if (index >= _filteredSubjects.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20.0),
                                  child: Center(
                                      child: CircularProgressIndicator(
                                          color: AppColors.primary)),
                                );
                              }
                              final subject = _filteredSubjects[index];
                              return GlassCard(
                                margin: EdgeInsets.symmetric(
                                    vertical: scaleConfig.scale(4)),
                                child: ListTile(
                                  leading: GradientIcon(
                                      icon: Icons.book_outlined, size: 30),
                                  title: Text(
                                    subject['name'] ?? 'no_name_fallback'.tr,
                                    style: theme.textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    subject['code'] ?? 'no_code_fallback'.tr,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () =>
                                      _showSubjectDetailsDialog(subject),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
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

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: 'search_subjects_hint'.tr,
        fillColor: theme.brightness == Brightness.dark
            ? Colors.transparent
            : theme.inputDecorationTheme.fillColor,
        border: theme.brightness == Brightness.dark
            ? InputBorder.none
            : theme.inputDecorationTheme.border,
      ).applyDefaults(theme.inputDecorationTheme).copyWith(
            prefixIcon:
                Icon(Icons.search, color: theme.textTheme.bodyMedium?.color),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear,
                        color: theme.textTheme.bodyMedium?.color),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
    );
  }
}