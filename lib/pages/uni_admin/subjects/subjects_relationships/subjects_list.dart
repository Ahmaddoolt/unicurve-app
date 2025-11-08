// lib/pages/uni_admin/subjects/subjects_relationships/subjects_list.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/subject.dart';

class SubjectsList extends StatelessWidget {
  final List<Map<String, dynamic>> subjects;
  final Subject? selectedSubject;
  final bool isLoading;
  final Function(Map<String, dynamic>) onSubjectTap;
  final Function(Map<String, dynamic>) onEditSubject;
  final Function(int) onDeleteSubject;

  const SubjectsList({
    super.key,
    required this.subjects,
    required this.selectedSubject,
    required this.isLoading,
    required this.onSubjectTap,
    required this.onEditSubject,
    required this.onDeleteSubject,
  });

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    Color? primaryTextColor = theme.textTheme.bodyLarge?.color;
    Color? secondaryTextColor = theme.textTheme.bodyMedium?.color;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GlassCard(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(scaleConfig.scale(16)),
              child: Text(
                'subjects_list_title'.tr,
                style: TextStyle(
                  fontSize: scaleConfig.scaleText(16),
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: scaleConfig.scale(8)),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  final isSelected = selectedSubject?.id == subject['id'];
                  return Card(
                    elevation: 0,
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(scaleConfig.scale(10)),
                      side: isSelected
                          ? const BorderSide(color: AppColors.primary)
                          : BorderSide.none,
                    ),
                    margin:
                        EdgeInsets.symmetric(vertical: scaleConfig.scale(4)),
                    child: ListTile(
                      title: Text(
                        subject['name'],
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: scaleConfig.scaleText(14),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      subtitle: Text(
                        'hours_label'
                            .trParams({'hours': '${subject['hours'] ?? 0}'}),
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: scaleConfig.scaleText(12),
                        ),
                      ),
                      onTap: () => onSubjectTap(subject),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
