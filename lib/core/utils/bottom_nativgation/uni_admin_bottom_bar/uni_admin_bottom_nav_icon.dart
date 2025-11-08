// lib/core/utils/bottom_nativgation/uni_admin_bottom_bar/uni_admin_bottom_nav_icon.dart

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
    final theme = Theme.of(context);
    // Use the filled icon when selected, outlined when not
    final iconData = isSelected ? _getFilledIcon(icon) : icon;

    if (isSelected) {
      final activeGradient = theme.brightness == Brightness.light
          ? AppColors.primaryGradient
          : AppColors.primaryGradient;

      return ShaderMask(
        shaderCallback: (bounds) => activeGradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        ),
        child: Icon(
          iconData,
          size: 31,
          color: Colors.white,
        ),
      );
    } else {
      return Icon(
        iconData,
        size: 31,
        color: theme.textTheme.bodyMedium?.color,
      );
    }
  }

  // Helper to get the filled version of an icon for selection
  IconData _getFilledIcon(IconData originalIcon) {
     Map<IconData, IconData> iconMap = {
      Icons.dashboard_outlined: Icons.dashboard,
      Icons.table_chart_outlined: Icons.table_chart,
      Icons.person_2_outlined: Icons.person_2,
    };
    return iconMap[originalIcon] ?? originalIcon;
  }
}
