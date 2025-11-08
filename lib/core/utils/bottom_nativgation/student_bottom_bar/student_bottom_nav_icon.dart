// lib/core/utils/bottom_nativgation/student_bottom_bar/student_bottom_nav_icon.dart

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
    final theme = Theme.of(context);
    // --- FIX: Use the superior filled/outlined logic ---
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
          color: Colors.white, // Color must be white for ShaderMask to work
        ),
      );
    } else {
      // Unselected icon remains the same (outlined)
      return Icon(
        iconData,
        size: 31,
        color: theme.textTheme.bodyMedium?.color,
      );
    }
  }

  // --- FIX: Copied the helper from UniAdmin for consistency ---
  IconData _getFilledIcon(IconData originalIcon) {
    // Map your student icons from outlined to filled versions
    Map<IconData, IconData> iconMap = {
      Icons.description_outlined: Icons.description,
      Icons.view_week_outlined: Icons.view_week,
      Icons.shape_line_outlined: Icons.shape_line,
      Icons.person_2_outlined: Icons.person_2,
    };
    return iconMap[originalIcon] ?? originalIcon;
  }
}
