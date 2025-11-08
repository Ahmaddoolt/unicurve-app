// lib/core/utils/widgets/gradient_border_card.dart

import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';

class GradientBorderCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Gradient gradient;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const GradientBorderCard({
    super.key,
    required this.child,
    required this.onTap,
    this.gradient = AppColors.primaryGradient,
    this.borderWidth = 1.5,
    this.borderRadius = 12.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            // Use a subtle shadow from the gradient itself for a nice glow effect
            color: AppColors.gradientBlueMid.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        // This padding creates the border effect
        padding: EdgeInsets.all(borderWidth),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          child: Ink(
            decoration: BoxDecoration(
              // The inner color of the card, matching the theme
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(borderRadius - borderWidth),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
