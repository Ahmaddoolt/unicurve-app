// lib/pages/student/planning_tools/term_gpa_calculator_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_floadt_action_button.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/glass_loading_overlay.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/student/student_profile/providers/academic_profile_provider.dart';
import 'package:unicurve/pages/student/student_profile/providers/university_cache_service.dart';

final availableSubjectsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final profileAsyncValue = ref.watch(academicProfileProvider);

  return profileAsyncValue.when(
    data: (profile) async {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in.');

      final majorId = profile.studentData?['major_id'];
      if (majorId == null) throw Exception('error_not_in_major'.tr);

      final subjectsResponse = await supabase
          .from('subjects')
          .select('id, name, hours')
          .eq('major_id', majorId);

      final takenIds = profile.takenSubjects
          .where((s) => s['subjects'] != null)
          .map((s) => s['subjects']['id'])
          .toSet();

      return List<Map<String, dynamic>>.from(
        subjectsResponse,
      ).where((s) => !takenIds.contains(s['id'])).toList();
    },
    loading: () => Future.value([]),
    error: (e, st) => throw e,
  );
});

class SubjectEntry {
  final int id;
  final String name;
  final int hours;
  int mark;
  final TextEditingController markController;

  SubjectEntry({
    required this.id,
    required this.name,
    required this.hours,
    this.mark = 85,
  }) : markController = TextEditingController(text: mark.toString());

  void dispose() {
    markController.dispose();
  }
}

class TermGpaCalculatorPage extends ConsumerStatefulWidget {
  const TermGpaCalculatorPage({super.key});

  @override
  ConsumerState<TermGpaCalculatorPage> createState() =>
      _TermGpaCalculatorPageState();
}

class _TermGpaCalculatorPageState extends ConsumerState<TermGpaCalculatorPage> {
  final List<SubjectEntry> _selectedSubjects = [];
  final UniversityCacheService _cacheService = UniversityCacheService();
  double _termGpa = 0.0;
  int _termHours = 0;
  double _projectedGpa = 0.0;
  String? _uniType;

  @override
  void initState() {
    super.initState();
    _loadUniType();
  }

  Future<void> _loadUniType() async {
    final cachedType = await _cacheService.getUniversityType();
    if (mounted) {
      setState(() {
        _uniType = cachedType;
      });
    }
  }

  @override
  void dispose() {
    for (var entry in _selectedSubjects) {
      entry.dispose();
    }
    super.dispose();
  }

  double _getGradePoint(int? mark, String? uniType) {
    if (mark == null) return 0.0;
    if (uniType == 'Public') {
      if (mark < 60) return 0.0;
      if (mark >= 98) return 4.0;
      if (mark >= 95) return 3.75;
      if (mark >= 90) return 3.5;
      if (mark >= 85) return 3.25;
      if (mark >= 80) return 3.0;
      if (mark >= 75) return 2.75;
      if (mark >= 70) return 2.5;
      if (mark >= 65) return 2.25;
      if (mark >= 60) return 2.0;
      return 0.0;
    }
    if (mark >= 98) return 4.0;
    if (mark >= 95) return 3.75;
    if (mark >= 90) return 3.5;
    if (mark >= 85) return 3.25;
    if (mark >= 80) return 3.0;
    if (mark >= 75) return 2.75;
    if (mark >= 70) return 2.5;
    if (mark >= 65) return 2.25;
    if (mark >= 60) return 2.0;
    if (mark >= 55) return 1.75;
    if (mark >= 50) return 1.5;
    return 0.0;
  }

  void _recalculateAll(AcademicProfile profile) {
    double termQualityPoints = 0;
    int termHours = 0;
    final currentUniType = profile.universityType ?? _uniType;

    for (final entry in _selectedSubjects) {
      termHours += entry.hours;
      termQualityPoints +=
          (_getGradePoint(entry.mark, currentUniType) * entry.hours);
    }

    final totalQualityPoints =
        profile.totalHistoricalQualityPoints + termQualityPoints;
    final totalHours = profile.totalHistoricalHours + termHours;

    if (!mounted) return;
    setState(() {
      _termHours = termHours;
      _termGpa = termHours > 0 ? termQualityPoints / termHours : 0.0;
      _projectedGpa = totalHours > 0 ? totalQualityPoints / totalHours : 0.0;
    });
  }

  void _showAddSubjectDialog(
    List<Map<String, dynamic>> allSubjects,
    AcademicProfile profile,
  ) {
    int? subjectToAddId;
    final availableSubjects = allSubjects
        .where((s) => !_selectedSubjects.any((ss) => ss.id == s['id']))
        .toList();

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          contentPadding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: GlassCard(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('add_subject_dialog_title'.tr,
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<int>(
                    hint: Text('select_subject_hint'.tr),
                    style: theme.textTheme.bodyLarge,
                    dropdownColor:
                        isDarkMode ? const Color(0xFF2D3748) : theme.cardColor,
                    icon: Icon(Icons.keyboard_arrow_down,
                        color: theme.textTheme.bodyMedium?.color),
                    items: availableSubjects
                        .map((s) => DropdownMenuItem<int>(
                              value: s['id'],
                              child: Text(s['name']),
                            ))
                        .toList(),
                    onChanged: (value) => subjectToAddId = value,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('cancel'.tr),
                      ),
                      const SizedBox(width: 8),
                      CustomButton(
                        onPressed: () {
                          if (subjectToAddId != null) {
                            final subjectData = allSubjects
                                .firstWhere((s) => s['id'] == subjectToAddId);
                            final int subjectHours =
                                subjectData['hours'] as int? ?? 0;
                            final newHours = _termHours + subjectHours;
                            if (newHours > 21) {
                              showFeedbackSnackbar(
                                  context, 'error_term_hours_exceed'.tr,
                                  isError: true);
                              return;
                            }
                            setState(() {
                              _selectedSubjects.add(SubjectEntry(
                                id: subjectData['id'],
                                name: subjectData['name'],
                                hours: subjectHours,
                              ));
                            });
                            _recalculateAll(profile);
                            Navigator.pop(context);
                          }
                        },
                        text: 'add_button'.tr,
                        gradient: AppColors.primaryGradient,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(academicProfileProvider);
    final subjectsAsync = ref.watch(availableSubjectsProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBar = CustomAppBar(
      useGradient: !isDarkMode,
      title: 'term_gpa_calculator_title'.tr,
    );

    final bodyContent = GlassLoadingOverlay(
      isLoading: (profileAsync.isLoading && !profileAsync.hasValue) ||
          (subjectsAsync.isLoading && !subjectsAsync.hasValue),
      child: profileAsync.when(
        data: (profile) {
          if (_uniType == null && profile.universityType != null) {
            _uniType = profile.universityType;
          }
          return subjectsAsync.when(
            data: (allSubjects) {
              return Column(
                children: [
                  _buildHeader(context.scaleConfig, profile),
                  Expanded(
                    child: _selectedSubjects.isEmpty
                        ? _buildEmptyState()
                        : _buildSubjectsList(profile),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, st) => Center(
                child: Text('error_load_subject_list'.tr,
                    style: const TextStyle(color: AppColors.error))),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (e, st) => Center(
            child: Text('error_load_profile_data'.tr,
                style: const TextStyle(color: AppColors.error))),
      ),
    );

    if (isDarkMode) {
      return GradientScaffold(
        appBar: appBar,
        body: bodyContent,
        floatingActionButton: _buildFAB(profileAsync, subjectsAsync),
      );
    } else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        body: bodyContent,
        floatingActionButton: _buildFAB(profileAsync, subjectsAsync),
      );
    }
  }

  Widget _buildFAB(AsyncValue<AcademicProfile> profileAsync,
      AsyncValue<List<Map<String, dynamic>>> subjectsAsync) {
    return CustomFAB(
      onPressed: profileAsync.hasValue && subjectsAsync.hasValue
          ? () =>
              _showAddSubjectDialog(subjectsAsync.value!, profileAsync.value!)
          : () {},
      tooltip: 'add_subject_tooltip'.tr,
    );
  }

  Widget _buildHeader(ScaleConfig scaleConfig, AcademicProfile profile) {
    if (_projectedGpa == 0.0 && _selectedSubjects.isEmpty) {
      final totalQualityPoints = profile.totalHistoricalQualityPoints;
      final totalHours = profile.totalHistoricalHours;
      _projectedGpa = totalHours > 0 ? totalQualityPoints / totalHours : 0.0;
    }

    return GlassCard(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeaderItem(
                    'term_gpa_label'.tr,
                    _termGpa.toStringAsFixed(2),
                    AppColors.primary,
                    scaleConfig),
                _buildHeaderItem('term_hours_label'.tr, "$_termHours / 21",
                    AppColors.accent, scaleConfig),
              ],
            ),
            Divider(height: 24, color: Theme.of(context).dividerColor),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_graph,
                    color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'projected_gpa_label'.tr,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: scaleConfig.scaleText(14),
                  ),
                ),
                const Spacer(),
                Text(
                  _projectedGpa.toStringAsFixed(2),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: scaleConfig.scaleText(22),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderItem(
      String label, String value, Color color, ScaleConfig scaleConfig) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: scaleConfig.scaleText(14),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: scaleConfig.scaleText(22),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_chart,
              size: 60, color: Theme.of(context).textTheme.bodyMedium?.color),
          const SizedBox(height: 16),
          Text(
            'empty_term_gpa_prompt'.tr,
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsList(AcademicProfile profile) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
      itemCount: _selectedSubjects.length,
      itemBuilder: (context, index) {
        final entry = _selectedSubjects[index];
        return GlassCard(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.name,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                          'hours_label'
                              .trParams({'hours': entry.hours.toString()}),
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    // Using TextFormField for consistency
                    controller: entry.markController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3)
                    ],
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'mark_label'.tr,
                    ).applyDefaults(Theme.of(context).inputDecorationTheme),
                    onChanged: (value) {
                      final newMark = int.tryParse(value) ?? 0;
                      if (newMark >= 0 && newMark <= 100) {
                        entry.mark = newMark;
                        _recalculateAll(profile);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppColors.error),
                  onPressed: () {
                    setState(() {
                      _selectedSubjects[index].dispose();
                      _selectedSubjects.removeAt(index);
                    });
                    _recalculateAll(profile);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
