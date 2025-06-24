import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';

class UniAdminBottomNavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const UniAdminBottomNavIcon({
    super.key,
    required this.icon,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      isSelected ? icon : _getOutlinedIcon(icon),
      size: 31,
      color: isSelected ? AppColors.primary : AppColors.lightTextSecondary,
    );
  }

  IconData _getOutlinedIcon(IconData originalIcon) {
    if (originalIcon == Icons.note_alt) {
      return Icons.note_alt_outlined;
    } else if (originalIcon == Icons.table_chart) {
      return Icons.table_chart_outlined;
    } else if (originalIcon == Icons.shape_line) {
      return Icons.shape_line_outlined;
    } else if (originalIcon == Icons.person_2) {
      return Icons.person_2_outlined;
    } else {
      return originalIcon;
    }
  }
}
