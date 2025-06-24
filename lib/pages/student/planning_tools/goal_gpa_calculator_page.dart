import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
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
            'gpa': ((historicalPoints + maxPossibleFuturePoints) /
                    totalMajorHours)
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
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: lighterColor,
      appBar: AppBar(
        title: Text('goal_gpa_calculator_title'.tr),
        centerTitle: true,
        backgroundColor: darkerColor,
      ),
      body: profileAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        error:
            (e, st) => Center(
              child: Text(
                'error_generic'.trParams({'error': e.toString()}),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
        data:
            (profile) => SingleChildScrollView(
              padding: EdgeInsets.all(scaleConfig.scale(16)),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildInputCard(profile),
                    const SizedBox(height: 24),
                    if (_hasCalculated)
                      _buildResults()
                    else
                      _buildInitialPrompt(),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildInputCard(AcademicProfile profile) {
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;

    return Card(
      color: darkerColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(
                  'current_gpa_label'.tr,
                  profile.cumulativeGpa.toStringAsFixed(2),
                ),
                _buildInfoChip(
                  'hours_done_label'.tr,
                  "${profile.completedHours}/${profile.totalMajorHours}",
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _gpaController,
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'enter_target_gpa_label'.tr,
                labelStyle: TextStyle(color: secondaryTextColor, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'error_enter_gpa'.tr;
                }
                final gpa = double.tryParse(value);
                if (gpa == null || gpa <= 0 || gpa > 4.0) {
                  return 'error_valid_gpa'.tr;
                }
                if (gpa <= profile.cumulativeGpa) {
                  return 'error_target_gpa_too_low'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculateGpaScenarios,
                icon: const Icon(Icons.calculate_outlined),
                label: Text('calculate_scenarios_button'.tr),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.primary,
                  foregroundColor: primaryTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;
    Color? lighterColor = Theme.of(context).cardColor;

    return Column(
      children: [
        Text(label, style: TextStyle(color: secondaryTextColor, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: lighterColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialPrompt() {
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Column(
      children: [
        Icon(Icons.insights, size: 80, color: secondaryTextColor),
        const SizedBox(height: 16),
        Text(
          'goal_prompt_title'.tr,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'goal_prompt_desc'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(color: secondaryTextColor, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildResults() {
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _scenarios.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final scenario = _scenarios[index];
        return Card(
          color: darkerColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color:
                  scenario.isPossible
                      // ignore: deprecated_member_use
                      ? AppColors.accent.withOpacity(0.5)
                      // ignore: deprecated_member_use
                      : AppColors.error.withOpacity(0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenario.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        scenario.isPossible
                            ? AppColors.accent
                            : AppColors.error,
                  ),
                ),
                Divider(height: 20, color: lighterColor),
                Text(
                  scenario.description,
                  style: TextStyle(color: secondaryTextColor, height: 1.5),
                ),
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
                              color: primaryTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        label: Text(
                          'gpa_chip_label'.trParams({
                            'gpa': scenario.termGpas[i],
                          }),
                        ),
                        // ignore: deprecated_member_use
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
