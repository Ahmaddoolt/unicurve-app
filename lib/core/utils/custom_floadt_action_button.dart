// lib/core/utils/custom_floadt_action_button.dart

import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';

class CustomFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;

  const CustomFAB({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    // UPDATED: Wrap the FAB in a Container with a gradient decoration
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FloatingActionButton(
        tooltip: tooltip,
        onPressed: onPressed,
        backgroundColor: Colors.transparent, // Make the FAB itself transparent
        elevation: 0, // Elevation is handled by the container's shadow
        highlightElevation: 0,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
