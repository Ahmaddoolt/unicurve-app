import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/subject.dart';
import 'relationship_adder.dart';
import 'relationship_item.dart';

class RelationshipsPanel extends StatelessWidget {
  final Subject? selectedSubject;
  final List<Map<String, dynamic>> relationships;
  final List<Map<String, dynamic>> availableSubjects;
  final bool isLoading;
  final Function(int, String, String) onAddRelationship;
  final Function(int, String, String) onRemoveRelationship;

  const RelationshipsPanel({
    super.key,
    required this.selectedSubject,
    required this.relationships,
    required this.availableSubjects,
    required this.isLoading,
    required this.onAddRelationship,
    required this.onRemoveRelationship,
  });

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;

    return Container(
      color: AppColors.darkBackground,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(scaleConfig.scale(16)),
            child: Text(
              selectedSubject != null
                  ? 'Relationships for ${selectedSubject!.name}'
                  : 'Select a Subject',
              style: TextStyle(
                fontSize: scaleConfig.scaleText(13),
                fontWeight: FontWeight.bold,
                color: AppColors.darkTextPrimary,
              ),
            ),
          ),
          if (selectedSubject != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: scaleConfig.scale(16),
                vertical: scaleConfig.scale(8),
              ),
              child: RelationshipAdder(
                availableSubjects: availableSubjects,
                isLoading: isLoading,
                onAddRelationship: (targetSubjectId, relationshipType) =>
                    onAddRelationship(selectedSubject!.id!, targetSubjectId, relationshipType),
              ),
            ),
            SizedBox(height: scaleConfig.scale(20)),
            Text(
              'Current Relationships:',
              style: TextStyle(
                fontSize: scaleConfig.scaleText(12),
                fontWeight: FontWeight.bold,
                color: AppColors.darkTextPrimary,
              ),
            ),
            if (relationships.isEmpty)
              Padding(
                padding: EdgeInsets.all(scaleConfig.scale(8)),
                child: Text(
                  'No relationships added yet',
                  style: TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: scaleConfig.scaleText(11),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(scaleConfig.scale(16)),
                children: relationships
                    .map((r) => RelationshipItem(
                          relationship: r,
                          availableSubjects: availableSubjects,
                          isLoading: isLoading,
                          onRemoveRelationship: () => onRemoveRelationship(
                            selectedSubject!.id!,
                            r['subject_id'],
                            r['type'],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}