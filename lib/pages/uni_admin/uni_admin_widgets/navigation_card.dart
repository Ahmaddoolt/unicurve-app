// lib/pages/uni_admin/uni_admin_widgets/navigation_card.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';

Widget buildNavigationCard(
  BuildContext context,
  ScaleConfig scaleConfig, {
  required String title,
  required IconData icon,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);
  final isDarkMode = theme.brightness == Brightness.dark;

  return Card(
    elevation: 6,
    shadowColor: isDarkMode
        ? Colors.black.withOpacity(0.5)
        : AppColors.gradientBlueMid.withOpacity(0.4),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(scaleConfig.scale(16)),
    ),
    margin: EdgeInsets.only(bottom: scaleConfig.scale(20)),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(scaleConfig.scale(16)),
      child: Container(
        height: scaleConfig.scale(140),
        width: double.infinity,
        padding: EdgeInsets.all(scaleConfig.scale(16)),
        decoration: BoxDecoration(
          // UPDATED: This now selects the correct gradient based on the theme
          gradient: isDarkMode
              ? AppColors.primaryGradient
              : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(scaleConfig.scale(16)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: scaleConfig.scaleText(22),
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Text on gradients is always white
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: scaleConfig.scale(8)),
                  Text(
                    'tap_to_manage_subtitle'.tr,
                    style: TextStyle(
                      fontSize: scaleConfig.scaleText(14),
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: scaleConfig.scale(35),
              // A slightly transparent black background looks great on both gradients
              backgroundColor: Colors.black.withOpacity(0.15),
              child: Icon(
                icon,
                color: Colors.white,
                size: scaleConfig.scale(30),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
