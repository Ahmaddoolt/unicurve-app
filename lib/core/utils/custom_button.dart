// lib/core/utils/custom_button.dart

import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  // --- UPDATE: Added a new gradient property ---
  final Gradient? gradient;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    // Check if a gradient is provided.
    final bool hasGradient = gradient != null;

    // This is the core button content. It's configured to be transparent
    // and have no elevation when a gradient is used, as the outer Container will handle it.
    final buttonContent = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: hasGradient
            ? Colors.transparent
            : (backgroundColor ?? AppColors.primary),
        foregroundColor: textColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation:
            hasGradient ? 0 : 2, // Remove inner shadow if gradient exists
        shadowColor:
            hasGradient ? Colors.transparent : Colors.black.withOpacity(0.2),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );

    // If a gradient is provided, wrap the button in a decorated Container.
    if (hasGradient) {
      return Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: buttonContent,
      );
    }

    // Otherwise, just return the standard button.
    return buttonContent;
  }
}
