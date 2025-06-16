import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';

class RelationshipItem extends StatelessWidget {
  final Map<String, dynamic> relationship;
  final List<Map<String, dynamic>> availableSubjects;
  final bool isLoading;
  final VoidCallback onRemoveRelationship;

  const RelationshipItem({
    super.key,
    required this.relationship,
    required this.availableSubjects,
    required this.isLoading,
    required this.onRemoveRelationship,
  });

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final subject = availableSubjects.firstWhere(
      (s) => s['id'] == relationship['subject_id'],
      orElse: () => {'code': 'Unknown', 'name': 'Subject'},
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(vertical: scaleConfig.scale(4)),
      child: Card(
        elevation: 4,
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        ),
        child: ListTile(
          title: Text(
            '${subject['name']}',
            style: TextStyle(
              color: AppColors.darkTextPrimary,
              fontSize: scaleConfig.scaleText(12),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            relationship['type'],
            style: TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: scaleConfig.scaleText(10),
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.delete,
              color: AppColors.error,
              size: scaleConfig.scale(20),
            ),
            onPressed: isLoading ? null : onRemoveRelationship,
            tooltip: 'Remove Relationship',
          ),
        ),
      ),
    );
  }
}
