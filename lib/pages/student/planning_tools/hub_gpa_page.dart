// lib/pages/student/planning_tools/hub_gpa_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/gradient_icon.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/student/planning_tools/goal_gpa_calculator_page.dart';
import 'package:unicurve/pages/student/planning_tools/term_gpa_calculator_page.dart';

class HubGpaPage extends StatelessWidget {
  const HubGpaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBar = CustomAppBar(
      useGradient: !isDarkMode,
      title: 'planning_tools_title'.tr,
    );

    final bodyContent = ListView(
      padding: EdgeInsets.all(scaleConfig.scale(16)),
      children: [
        _buildToolCard(
          context: context,
          icon: Icons.calculate_outlined,
          title: 'term_gpa_card_title'.tr,
          description: 'term_gpa_card_desc'.tr,
          gradient: AppColors.primaryGradient, // Use gradient for the icon
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TermGpaCalculatorPage(),
              ),
            );
          },
        ),
        SizedBox(height: scaleConfig.scale(16)),
        _buildToolCard(
          context: context,
          icon: Icons.track_changes_outlined,
          title: 'goal_gpa_card_title'.tr,
          description: 'goal_gpa_card_desc'.tr,
          gradient:
              AppColors.accentGradient, // Use a different gradient for variety
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GoalGpaCalculatorPage(),
              ),
            );
          },
        ),
      ],
    );

    if (isDarkMode) {
      return GradientScaffold(
        appBar: appBar,
        body: bodyContent,
      );
    } else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        body: bodyContent,
      );
    }
  }

  Widget _buildToolCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);

    // --- THE KEY FIX IS HERE: Using GlassCard for consistency ---
    return GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(scaleConfig.scale(16)),
          child: Row(
            children: [
              // --- FIX: Using GradientIcon for a premium look ---
              GradientIcon(
                icon: icon,
                size: scaleConfig.scale(40),
                gradient: gradient,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: scaleConfig.scaleText(17),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: scaleConfig.scaleText(14),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: theme.textTheme.bodyMedium?.color),
            ],
          ),
        ),
      ),
    );
  }
}
