// lib/pages/student/planning_tools_hub_page.dart

import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/student/goal_gpa_calculator_page.dart';
import 'package:unicurve/pages/student/term_gpa_calculator_page.dart';

class HubGpaPage extends StatelessWidget {
  const HubGpaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        title: const Text("Planning Tools"),
        centerTitle: true,
        backgroundColor: AppColors.darkBackground,
      ),
      body: ListView(
        padding: EdgeInsets.all(scaleConfig.scale(16)),
        children: [
          _buildToolCard(
            context: context,
            icon: Icons.calculate_outlined,
            title: "Term GPA Calculator",
            description: "Calculate your GPA for the current or a hypothetical term.",
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermGpaCalculatorPage()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildToolCard(
            context: context,
            icon: Icons.track_changes_outlined,
            title: "Goal GPA Calculator",
            description: "Find out what you need to achieve your target cumulative GPA.",
            color: AppColors.accent,
            onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GoalGpaCalculatorPage()),
              );
            },
          ),
          // You can easily add more cards here in the future!
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final scaleConfig = context.scaleConfig;
    return Card(
      color: AppColors.darkBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        child: Padding(
          padding: EdgeInsets.all(scaleConfig.scale(16)),
          child: Row(
            children: [
              Icon(icon, size: scaleConfig.scale(40), color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: scaleConfig.scaleText(18),
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: scaleConfig.scaleText(14),
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: AppColors.darkTextSecondary),
            ],
          ),
        ),
      ),
    );
  }
}