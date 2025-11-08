// lib/pages/uni_admin/subjects/subjects_relationships/relationships_panel.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/glass_card.dart';
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
    final theme = Theme.of(context);
    Color? primaryTextColor = theme.textTheme.bodyLarge?.color;
    Color? secondaryTextColor = theme.textTheme.bodyMedium?.color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
      child: GlassCard(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(scaleConfig.scale(16)),
              child: Text(
                selectedSubject != null
                    ? 'relationships_panel_title'
                        .trParams({'subjectName': selectedSubject!.name})
                    : 'relationships_panel_placeholder'.tr,
                style: TextStyle(
                  fontSize: scaleConfig.scaleText(16),
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
                textAlign: TextAlign.center,
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
                      onAddRelationship(
                    selectedSubject!.id!,
                    targetSubjectId,
                    relationshipType,
                  ),
                ),
              ),
              SizedBox(height: scaleConfig.scale(20)),
              Text(
                'add_relations_section_current_title'.tr,
                style: TextStyle(
                  fontSize: scaleConfig.scaleText(14),
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              if (relationships.isEmpty)
                Padding(
                  padding: EdgeInsets.all(scaleConfig.scale(16)),
                  child: Text(
                    'add_relations_no_relations_yet'.tr,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: scaleConfig.scaleText(14),
                    ),
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(scaleConfig.scale(16)),
                  children: relationships
                      .map(
                        (r) => RelationshipItem(
                          relationship: r,
                          availableSubjects: availableSubjects,
                          isLoading: isLoading,
                          onRemoveRelationship: () => onRemoveRelationship(
                            selectedSubject!.id!,
                            r['subject_id'],
                            r['type'],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
