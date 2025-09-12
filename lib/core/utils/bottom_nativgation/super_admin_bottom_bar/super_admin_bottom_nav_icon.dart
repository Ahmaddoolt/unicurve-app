import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';

class SuperAdminBottomNavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const SuperAdminBottomNavIcon({
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
    if (originalIcon == Icons.admin_panel_settings) {
      return Icons.admin_panel_settings_outlined;
    } else if (originalIcon == Icons.settings) {
      return Icons.settings_outlined;
    } else {
      return originalIcon;
    }
  }
}
