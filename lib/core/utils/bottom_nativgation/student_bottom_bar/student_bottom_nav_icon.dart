import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';

class StudentBottomNavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const StudentBottomNavIcon({
    super.key,
    required this.icon,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      isSelected ? icon : _getOutlinedIcon(icon),
      size: 30,
      color: isSelected ? AppColors.primary : AppColors.lightTextSecondary,
    );
  }

  IconData _getOutlinedIcon(IconData originalIcon) {
    if (originalIcon == Icons.description) {
      return Icons.description_outlined;
    } else if (originalIcon == Icons.view_week) {
      return Icons.view_week_outlined;
    } else if (originalIcon == Icons.shape_line) {
      return Icons.shape_line_outlined;
    } else if (originalIcon == Icons.person_2) {
      return Icons.person_2_outlined;
    } else {
      return originalIcon;
    }
  }
}
