// lib/pages/student/goal_gpa_calculator_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/student/providers/academic_profile_provider.dart';

// Data class for a single calculation result
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
      // Handle graduated student case
      setState(() {
        _scenarios = [GpaScenario(title: "Graduated!", description: "You have completed all required hours.", isPossible: false)];
        _hasCalculated = true;
      });
      return;
    }

    List<GpaScenario> newScenarios = [];
    
    // --- STEP 1: Check if the goal is possible at all ---
    final requiredTotalPoints = targetGpa * totalMajorHours;
    final pointsNeededInFuture = requiredTotalPoints - historicalPoints;
    final maxPossibleFuturePoints = 4.0 * remainingHours;

    if (pointsNeededInFuture > maxPossibleFuturePoints) {
      newScenarios.add(GpaScenario(
        title: "Target GPA is Not Possible",
        description: "Even with a perfect 4.0 in all remaining subjects, the highest GPA you can achieve is ${((historicalPoints + maxPossibleFuturePoints) / totalMajorHours).toStringAsFixed(2)}. Please try a lower target.",
        isPossible: false,
      ));
    } else {
      // --- If possible, proceed with all scenarios ---

      // --- STEP 2: Always show Immediate Term Scenarios ---
      newScenarios.add(GpaScenario(title: "Short-Term Paths", description: "Here's what you would need to achieve in the near future to reach your goal."));
      
      bool immediateScenarioFound = false;
      for (int terms = 1; terms <= 3; terms++) {
        int termHours = terms * 18;
        if (termHours > remainingHours) termHours = remainingHours;

        final newTotalHours = historicalHours + termHours;
        final totalPointsNeeded = targetGpa * newTotalHours;
        final pointsNeededThisPeriod = totalPointsNeeded - historicalPoints;
        final gpaNeeded = pointsNeededThisPeriod / termHours;

        if (gpaNeeded > 0 && gpaNeeded <= 4.0) {
          newScenarios.add(GpaScenario(
            title: "Option: In $terms Term(s)",
            description: "To reach a cumulative GPA of ${targetGpa.toStringAsFixed(2)} within the next $terms term(s) (approx. $termHours hours), you would need to maintain an average GPA of ${gpaNeeded.toStringAsFixed(2)}.",
            isPossible: true,
          ));
          immediateScenarioFound = true;
        }
      }
      if (!immediateScenarioFound) {
        newScenarios.add(GpaScenario(
            title: "Short-Term Goal Unlikely",
            description: "Reaching this GPA in the next 1-3 terms would require an average GPA higher than 4.0. Consider a long-term strategy.",
            isPossible: false,
        ));
      }

      // --- STEP 3: Always show Long-Term Scenarios ---
      final requiredFutureGpa = pointsNeededInFuture / remainingHours;
      _addTermDistributionScenarios(newScenarios, remainingHours, requiredFutureGpa);
    }
    
    setState(() {
      _scenarios = newScenarios;
      _hasCalculated = true;
    });
    FocusScope.of(context).unfocus();
  }

  void _addTermDistributionScenarios(List<GpaScenario> scenarios, int remainingHours, double requiredFutureGpa) {
    scenarios.add(GpaScenario(title: "Long-Term Paths", description: "Alternatively, here are some strategies spread across all of your remaining $remainingHours hours."));
    
    final normalTerms = (remainingHours / 18).ceil();
    if (normalTerms > 1) {
      scenarios.add(GpaScenario(
        title: "Scenario 1: Steady Pace",
        description: "Maintain a consistent GPA across $normalTerms terms (at ~18 hours/term):",
        termGpas: List.generate(normalTerms, (_) => requiredFutureGpa.toStringAsFixed(2)),
      ));
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
      scenarios.add(GpaScenario(
        title: "Scenario 2: Gradual Improvement",
        description: "Slowly increase your term GPA over the next $normalTerms terms:",
        termGpas: gradualGpas,
      ));
    }

    if (normalTerms > 1) {
      double firstTermGpa = requiredFutureGpa + 0.2;
      if (firstTermGpa <= 4.0) {
        final List<String> strongStartGpas = [firstTermGpa.toStringAsFixed(2)];
        double remainingPoints = (requiredFutureGpa * remainingHours) - (firstTermGpa * 18);
        int restOfHours = remainingHours - 18;
        if(restOfHours > 0) {
          double restOfGpa = remainingPoints / restOfHours;
          if (restOfGpa <= 4.0 && restOfGpa > 0) {
            for (int i = 0; i < normalTerms - 1; i++) {
              strongStartGpas.add(restOfGpa.toStringAsFixed(2));
            }
            scenarios.add(GpaScenario(
              title: "Scenario 3: Strong Start",
              description: "Achieve a higher GPA in your next term to ease the pressure later:",
              termGpas: strongStartGpas,
            ));
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

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        title: const Text("Goal GPA Calculator"),
        centerTitle: true,
        backgroundColor: AppColors.darkBackground,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, st) => Center(child: Text("Error: $e", style: const TextStyle(color: AppColors.error))),
        data: (profile) => SingleChildScrollView(
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
    return Card(
      color: AppColors.darkBackground,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip("Current GPA", profile.cumulativeGpa.toStringAsFixed(2)),
                _buildInfoChip("Hours Done", "${profile.completedHours}/${profile.totalMajorHours}"),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _gpaController,
              style: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              decoration: InputDecoration(
                labelText: "Enter Your Target GPA",
                labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primary), borderRadius: BorderRadius.circular(8)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter a GPA';
                final gpa = double.tryParse(value);
                if (gpa == null || gpa <= 0 || gpa > 4.0) return 'Enter a valid GPA (0.01-4.00)';
                if (gpa <= profile.cumulativeGpa) return 'Target must be higher than current GPA';
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculateGpaScenarios,
                icon: const Icon(Icons.calculate_outlined),
                label: const Text("Calculate Scenarios"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(20)),
          child: Text(value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
        )
      ],
    );
  }

  Widget _buildInitialPrompt() {
    return const Column(
      children: [
        Icon(Icons.insights, size: 80, color: AppColors.darkTextSecondary),
        SizedBox(height: 16),
        Text("What's your goal?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary)),
        SizedBox(height: 8),
        Text("Enter your target cumulative GPA to see how you can achieve it.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 16)),
      ],
    );
  }

  Widget _buildResults() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _scenarios.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final scenario = _scenarios[index];
        return Card(
          color: AppColors.darkBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: scenario.isPossible ? AppColors.accent.withOpacity(0.5) : AppColors.error.withOpacity(0.5))
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenario.title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scenario.isPossible ? AppColors.accent : AppColors.error),
                ),
                const Divider(height: 20, color: AppColors.darkSurface),
                Text(scenario.description, style: const TextStyle(color: AppColors.darkTextSecondary, height: 1.5)),
                if (scenario.termGpas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(scenario.termGpas.length, (i) => Chip(
                      avatar: CircleAvatar(backgroundColor: AppColors.primary, child: Text("${i+1}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                      label: Text("${scenario.termGpas[i]} GPA"),
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
                    )),
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}