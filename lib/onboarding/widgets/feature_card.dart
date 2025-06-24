// lib/onboarding/widgets/feature_card.dart
import 'package:flutter/material.dart';
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleConfig.scale(24)),
      child: Container(
        padding: EdgeInsets.all(scaleConfig.scale(20)),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(scaleConfig.scale(16)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF24C28F), size: scaleConfig.scale(32)),
            SizedBox(width: scaleConfig.scale(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: scaleConfig.scaleText(18),
                    ),
                  ),
                  SizedBox(height: scaleConfig.scale(6)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
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
    );
  }
}