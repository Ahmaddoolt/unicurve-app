import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';

Widget buildNavigationCard(
  BuildContext context,
  ScaleConfig scaleConfig, {
  required String title,
  required IconData icon,
  required VoidCallback onTap,
}) {
  final cardWidth =
      scaleConfig.isTablet
          ? scaleConfig.widthPercentage(0.88)
          : scaleConfig.widthPercentage(0.9);
  final cardHeight =
      scaleConfig.isTablet ? scaleConfig.scale(150) : scaleConfig.scale(162);

  // Fixed: Provide a default color if theme color is null

  return Card(
    elevation: 5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
    ),
    margin: EdgeInsets.only(bottom: scaleConfig.scale(24)),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
      child: Container(
        height: cardHeight,
        width: cardWidth,
        padding: EdgeInsets.all(scaleConfig.scale(12)),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryDark, width: 4),
          gradient: LinearGradient(
            colors: [
              Colors.black,
              AppColors.darkSurface,
              AppColors.darkBackground,
              AppColors.darkSurface,
              AppColors.darkBackground,
              AppColors.darkSurface,
              Colors.black
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: scaleConfig.scaleText(14),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: scaleConfig.scale(8)),
                  Text(
                    'Tap to manage',
                    style: TextStyle(
                      fontSize: scaleConfig.scaleText(12),
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Icon(
                icon,
                color: AppColors.primary,
                size: scaleConfig.scale(40),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
