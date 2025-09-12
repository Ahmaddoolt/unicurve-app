import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/major.dart';
import 'package:unicurve/pages/uni_admin/majors/views/manage_major_requirements_page.dart';

class MajorListTile extends StatelessWidget {
  final Major major;
  final VoidCallback onEdit;

  const MajorListTile({super.key, required this.major, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final scaleConfig = ScaleConfig(context);
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Card(
      elevation: 2,
      color: darkerColor,
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
          backgroundColor: lighterColor,
          child: Icon(
            Icons.school,
            color: AppColors.primary,
            size: scaleConfig.scale(20),
          ),
        ),
        title: Text(
          major.name,
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.w600,
            fontSize: scaleConfig.scaleText(16),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.rule_folder_outlined,
                color: AppColors.accent,
                size: scaleConfig.scale(20),
              ),
              tooltip: 'major_tile_manage_reqs_tooltip'.tr,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ManageMajorRequirementsPage(major: major),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.edit,
                color: secondaryTextColor,
                size: scaleConfig.scale(20),
              ),
              tooltip: 'major_tile_edit_name_tooltip'.tr,
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}
