// lib/pages/student/planning_tools/goal_gpa_calculator_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/glass_loading_overlay.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/student/student_profile/providers/academic_profile_provider.dart';

class GpaScenario {
  final String title;
  final String description;
  final bool isPossible;
  final List<String> termGpas;

  GpaScenario({
    required this.title,
    required this.description,
    this.isPossible = true,
    this.termGpas = const [],
  });
}

class GoalGpaCalculatorPage extends ConsumerStatefulWidget {
  const GoalGpaCalculatorPage({super.key});

  @override
  ConsumerState<GoalGpaCalculatorPage> createState() =>
      _GoalGpaCalculatorPageState();
}

class _GoalGpaCalculatorPageState extends ConsumerState<GoalGpaCalculatorPage> {
  final _gpaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<GpaScenario> _scenarios = [];
  bool _hasCalculated = false;

  void _calculateGpaScenarios() {
    if (!_formKey.currentState!.validate()) return;

    final targetGpa = double.tryParse(_gpaController.text);
    if (targetGpa == null) return;

    final profile = ref.read(academicProfileProvider).value;
    if (profile == null) return;

    final historicalPoints = profile.totalHistoricalQualityPoints;
    final historicalHours = profile.totalHistoricalHours;
    final totalMajorHours = profile.totalMajorHours;

    final remainingHours = totalMajorHours - historicalHours;
    if (remainingHours <= 0) {
      setState(() {
        _scenarios = [
          GpaScenario(
            title: 'graduated_title'.tr,
            description: 'graduated_desc'.tr,
            isPossible: false,
          ),
        ];
        _hasCalculated = true;
      });
      return;
    }

    List<GpaScenario> newScenarios = [];
    final requiredTotalPoints = targetGpa * totalMajorHours;
    final pointsNeededInFuture = requiredTotalPoints - historicalPoints;
    final maxPossibleFuturePoints = 4.0 * remainingHours;

    if (pointsNeededInFuture > maxPossibleFuturePoints) {
      newScenarios.add(
        GpaScenario(
          title: 'goal_not_possible_title'.tr,
          description: 'goal_not_possible_desc'.trParams({
            'gpa':
                ((historicalPoints + maxPossibleFuturePoints) / totalMajorHours)
                    .toStringAsFixed(2),
          }),
          isPossible: false,
        ),
      );
    } else {
      newScenarios.add(
        GpaScenario(
          title: 'short_term_paths_title'.tr,
          description: 'short_term_paths_desc'.tr,
        ),
      );

      bool immediateScenarioFound = false;
      for (int terms = 1; terms <= 3; terms++) {
        int termHours = terms * 18;
        if (termHours > remainingHours) termHours = remainingHours;
        if (termHours <= 0) continue;

        final newTotalHours = historicalHours + termHours;
        final totalPointsNeeded = targetGpa * newTotalHours;
        final pointsNeededThisPeriod = totalPointsNeeded - historicalPoints;
        final gpaNeeded = pointsNeededThisPeriod / termHours;

        if (gpaNeeded > 0 && gpaNeeded <= 4.0) {
          newScenarios.add(
            GpaScenario(
              title: 'option_in_terms_title'.trParams({
                'terms': terms.toString(),
              }),
              description: 'option_in_terms_desc'.trParams({
                'targetGpa': targetGpa.toStringAsFixed(2),
                'terms': terms.toString(),
                'hours': termHours.toString(),
                'neededGpa': gpaNeeded.toStringAsFixed(2),
              }),
              isPossible: true,
            ),
          );
          immediateScenarioFound = true;
        }
      }
      if (!immediateScenarioFound) {
        newScenarios.add(
          GpaScenario(
            title: 'short_term_unlikely_title'.tr,
            description: 'short_term_unlikely_desc'.tr,
            isPossible: false,
          ),
        );
      }

      final requiredFutureGpa = pointsNeededInFuture / remainingHours;
      _addTermDistributionScenarios(
        newScenarios,
        remainingHours,
        requiredFutureGpa,
      );
    }

    setState(() {
      _scenarios = newScenarios;
      _hasCalculated = true;
    });
    FocusScope.of(context).unfocus();
  }

  void _addTermDistributionScenarios(
    List<GpaScenario> scenarios,
    int remainingHours,
    double requiredFutureGpa,
  ) {
    scenarios.add(
      GpaScenario(
        title: 'long_term_paths_title'.tr,
        description: 'long_term_paths_desc'.trParams({
          'hours': remainingHours.toString(),
        }),
      ),
    );

    final normalTerms = (remainingHours / 18).ceil();
    if (normalTerms > 1) {
      scenarios.add(
        GpaScenario(
          title: 'steady_pace_title'.tr,
          description: 'steady_pace_desc'.trParams({
            'terms': normalTerms.toString(),
          }),
          termGpas: List.generate(
            normalTerms,
            (_) => requiredFutureGpa.toStringAsFixed(2),
          ),
        ),
      );
    }

    if (normalTerms > 2 && requiredFutureGpa > 0.2 && requiredFutureGpa < 3.8) {
      final List<String> gradualGpas = [];
      double startGpa = requiredFutureGpa - 0.1;
      double increment = 0.2 / (normalTerms - 1);
      for (int i = 0; i < normalTerms; i++) {
        double termGpa = startGpa + (i * increment);
        if (termGpa > 4.0) termGpa = 4.0;
        if (termGpa < 0) termGpa = 0;
        gradualGpas.add(termGpa.toStringAsFixed(2));
      }
      scenarios.add(
        GpaScenario(
          title: 'gradual_improvement_title'.tr,
          description: 'gradual_improvement_desc'.trParams({
            'terms': normalTerms.toString(),
          }),
          termGpas: gradualGpas,
        ),
      );
    }

    if (normalTerms > 1) {
      double firstTermGpa = requiredFutureGpa + 0.2;
      if (firstTermGpa <= 4.0) {
        final List<String> strongStartGpas = [firstTermGpa.toStringAsFixed(2)];
        double remainingPoints =
            (requiredFutureGpa * remainingHours) - (firstTermGpa * 18);
        int restOfHours = remainingHours - 18;
        if (restOfHours > 0) {
          double restOfGpa = remainingPoints / restOfHours;
          if (restOfGpa <= 4.0 && restOfGpa > 0) {
            for (int i = 0; i < normalTerms - 1; i++) {
              strongStartGpas.add(restOfGpa.toStringAsFixed(2));
            }
            scenarios.add(
              GpaScenario(
                title: 'strong_start_title'.tr,
                description: 'strong_start_desc'.tr,
                termGpas: strongStartGpas,
              ),
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _gpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final profileAsync = ref.watch(academicProfileProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBar = CustomAppBar(
      useGradient: !isDarkMode,
      title: 'goal_gpa_calculator_title'.tr,
    );

    final bodyContent = GlassLoadingOverlay(
      isLoading: profileAsync.isLoading && !profileAsync.hasValue,
      child: profileAsync.when(
        data: (profile) => SingleChildScrollView(
          padding: EdgeInsets.all(scaleConfig.scale(16)),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildInputCard(profile, theme, scaleConfig),
                // const SizedBox(height: 0),
                if (_hasCalculated)
                  _buildResults(theme, scaleConfig)
                else
                  _buildInitialPrompt(theme),
              ],
            ),
          ),
        ),
        loading: () => const SizedBox.shrink(),
        error: (e, st) => Center(
          child: Text(
            'error_generic'.trParams({'error': e.toString()}),
            style: const TextStyle(color: AppColors.error),
          ),
        ),
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

  // --- THIS WIDGET IS COMPLETELY REDESIGNED TO MATCH THE SCREENSHOT ---
  Widget _buildInputCard(
      AcademicProfile profile, ThemeData theme, ScaleConfig scaleConfig) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoChip(theme, 'current_gpa_label'.tr,
                    profile.cumulativeGpa.toStringAsFixed(2)),
                _buildInfoChip(theme, 'hours_done_label'.tr,
                    "${profile.completedHours}/${profile.totalMajorHours}"),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _gpaController,
              style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color),
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'enter_target_gpa_label'.tr,
                labelStyle: theme.textTheme.labelLarge,
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.3)
                    : AppColors.lightSurface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'error_enter_gpa'.tr;
                final gpa = double.tryParse(value);
                if (gpa == null || gpa <= 0 || gpa > 4.0)
                  return 'error_valid_gpa'.tr;
                if (gpa <= profile.cumulativeGpa)
                  return 'error_target_gpa_too_low'.tr;
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: _calculateGpaScenarios,
                text: 'calculate_scenarios_button'.tr,
                gradient: AppColors.primaryGradient,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- THIS WIDGET IS UPDATED TO MATCH THE SCREENSHOT'S STYLE ---
  Widget _buildInfoChip(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.25)
                : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialPrompt(ThemeData theme) {
    return Column(
      children: [
        Icon(Icons.insights,
            size: 80, color: theme.textTheme.bodyMedium?.color),
        const SizedBox(height: 16),
        Text('goal_prompt_title'.tr, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'goal_prompt_desc'.tr,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildResults(ThemeData theme, ScaleConfig scaleConfig) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _scenarios.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final scenario = _scenarios[index];
        return GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenario.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scenario.isPossible
                        ? AppColors.accent
                        : AppColors.error,
                  ),
                ),
                Divider(height: 20, color: theme.dividerColor),
                Text(scenario.description, style: theme.textTheme.bodyMedium),
                if (scenario.termGpas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      scenario.termGpas.length,
                      (i) => Chip(
                        avatar: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            "${i + 1}",
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        label: Text('gpa_chip_label'
                            .trParams({'gpa': scenario.termGpas[i]})),
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        labelStyle: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
