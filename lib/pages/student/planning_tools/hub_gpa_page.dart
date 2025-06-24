import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/student/planning_tools/goal_gpa_calculator_page.dart';
import 'package:unicurve/pages/student/planning_tools/term_gpa_calculator_page.dart';

class HubGpaPage extends StatelessWidget {
  const HubGpaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: lighterColor,
      appBar: AppBar(
        title: Text('planning_tools_title'.tr),
        centerTitle: true,
        backgroundColor: darkerColor,
      ),
      body: ListView(
        padding: EdgeInsets.all(scaleConfig.scale(16)),
        children: [
          _buildToolCard(
            context: context,
            icon: Icons.calculate_outlined,
            title: 'term_gpa_card_title'.tr,
            description: 'term_gpa_card_desc'.tr,
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermGpaCalculatorPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildToolCard(
            context: context,
            icon: Icons.track_changes_outlined,
            title: 'goal_gpa_card_title'.tr,
            description: 'goal_gpa_card_desc'.tr,
            color: AppColors.accent,
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
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;

    return Card(
      color: darkerColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        // ignore: deprecated_member_use
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
                        fontSize: scaleConfig.scaleText(16),
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: scaleConfig.scaleText(13),
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: secondaryTextColor),
            ],
          ),
        ),
      ),
    );
  }
}
