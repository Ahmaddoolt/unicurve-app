// lib/onboarding/widgets/feature_card.dart

import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/glass_card.dart'; // --- FIX: Import GlassCard ---
import 'package:unicurve/core/utils/gradient_icon.dart'; // --- FIX: Import GradientIcon ---
import 'package:unicurve/core/utils/scale_config.dart';

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleConfig.scale(24)),
      // --- THE KEY FIX IS HERE ---
      child: GlassCard(
        borderRadius: BorderRadius.circular(scaleConfig.scale(16)),
        child: Padding(
          padding: EdgeInsets.all(scaleConfig.scale(20)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientIcon(
                  icon: icon,
                  size: scaleConfig.scale(32),
                  gradient: AppColors.accentGradient),
              SizedBox(width: scaleConfig.scale(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: scaleConfig.scaleText(18),
                      ),
                    ),
                    SizedBox(height: scaleConfig.scale(6)),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: scaleConfig.scaleText(14),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
