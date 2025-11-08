// lib/core/utils/glass_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? borderColor; // --- NEW: Add borderColor property ---

  const GlassCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius,
    this.color,
    this.borderColor, // --- NEW: Add to constructor ---
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Use a standard Card in light mode
    if (!isDarkMode) {
      return Card(
        color: color ?? theme.cardColor,
        margin: margin,
        // --- FIX: Use the provided borderColor in light mode ---
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12.0),
          side: borderColor != null
              ? BorderSide(color: borderColor!, width: 1.5)
              : theme.cardTheme.shape is RoundedRectangleBorder
                  ? ((theme.cardTheme.shape as RoundedRectangleBorder).side)
                  : const BorderSide(color: Colors.transparent),
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      );
    }

    // Use the Glassmorphism effect in dark mode
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(12.0),
            color: color ?? Colors.white.withOpacity(0.1),
            // --- FIX: Use the provided borderColor in dark mode ---
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
