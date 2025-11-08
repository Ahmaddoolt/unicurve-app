// lib/core/utils/bottom_nativgation/super_admin_bottom_bar/super_admin_bottom_nav_icon.dart

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
    final theme = Theme.of(context);
    final iconData = isSelected ? icon : _getOutlinedIcon(icon);

    if (isSelected) {
      // UPDATED: Selects the correct gradient based on theme brightness
      final activeGradient = theme.brightness == Brightness.light
          ? AppColors.primaryGradient
          : AppColors.primaryGradient;

      return ShaderMask(
        shaderCallback: (bounds) => activeGradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        ),
        child: Icon(
          iconData,
          size: 30,
          color: Colors.white,
        ),
      );
    } else {
      return Icon(
        iconData,
        size: 30,
        color: theme.textTheme.bodyMedium?.color,
      );
    }
  }

  IconData _getOutlinedIcon(IconData originalIcon) {
     Map<IconData, IconData> iconMap = {
      Icons.admin_panel_settings: Icons.admin_panel_settings_outlined,
      Icons.settings: Icons.settings_outlined,
    };
    return iconMap[originalIcon] ?? originalIcon;
  }
}
