import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';

class CustomFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const CustomFAB({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 3),
      ),
      child: FloatingActionButton(
        backgroundColor: AppColors.darkBackground,
        onPressed: onPressed,
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}
