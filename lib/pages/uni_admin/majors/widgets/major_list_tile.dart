// lib/pages/uni_admin/majors/widgets/major_list_tile.dart

import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/major.dart';
// Import the new requirements page we will create
import 'package:unicurve/pages/uni_admin/majors/views/manage_major_requirements_page.dart';

class MajorListTile extends StatelessWidget {
  final Major major;
  final VoidCallback onEdit; // Renamed for clarity

  const MajorListTile({
    super.key,
    required this.major,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scaleConfig = ScaleConfig(context);

    return Card(
      elevation: 2,
      color: AppColors.darkBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        side: const BorderSide(color: AppColors.primaryDark, width: 1.5),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: scaleConfig.scale(16),
          vertical: scaleConfig.scale(8),
        ),
        leading: CircleAvatar(
          radius: scaleConfig.scale(20),
          backgroundColor: AppColors.darkSurface,
          child: Icon(
            Icons.school,
            color: AppColors.primary,
            size: scaleConfig.scale(20),
          ),
        ),
        title: Text(
          major.name,
          style: TextStyle(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: scaleConfig.scaleText(16),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- NEW: Icon button to manage requirements ---
            IconButton(
              icon: Icon(
                Icons.rule_folder_outlined, // An icon representing rules/requirements
                color: AppColors.accent,
                size: scaleConfig.scale(20),
              ),
              tooltip: 'Manage Requirements',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageMajorRequirementsPage(major: major),
                  ),
                );
              },
            ),
            // --- EXISTING: Icon button to edit the major's name ---
            IconButton(
              icon: Icon(
                Icons.edit,
                color: AppColors.darkTextSecondary,
                size: scaleConfig.scale(20),
              ),
               tooltip: 'Edit Major Name',
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}