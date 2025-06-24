import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/core/utils/scale_config.dart';

class RelationshipAdder extends StatefulWidget {
  final List<Map<String, dynamic>> availableSubjects;
  final bool isLoading;
  final Function(String, String) onAddRelationship;

  const RelationshipAdder({
    super.key,
    required this.availableSubjects,
    required this.isLoading,
    required this.onAddRelationship,
  });

  @override
  RelationshipAdderState createState() => RelationshipAdderState();
}

class RelationshipAdderState extends State<RelationshipAdder> {
  String? selectedSubjectId;
  String? selectedType;

  void _resetForm() {
    setState(() {
      selectedSubjectId = null;
      selectedType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Card(
      elevation: 6,
      color: lighterColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
      ),
      child: Padding(
        padding: EdgeInsets.all(scaleConfig.scale(16)),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'subject_label'.tr,
                labelStyle: TextStyle(
                  color: secondaryTextColor,
                  fontSize: scaleConfig.scaleText(12),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                  borderSide: BorderSide(
                    // ignore: deprecated_member_use
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                ),
              ),
              dropdownColor: lighterColor,
              items:
                  widget.availableSubjects.map((subject) {
                    return DropdownMenuItem<String>(
                      value: subject['id'].toString(),
                      child: Text(
                        '${subject['name']} (${subject['code']})',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: scaleConfig.scaleText(12),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
              onChanged:
                  widget.isLoading
                      ? null
                      : (value) => setState(() => selectedSubjectId = value),
              validator:
                  (value) =>
                      value == null
                          ? 'add_relations_error_select_subject'.tr
                          : null,
            ),
            SizedBox(height: scaleConfig.scale(12)),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'add_relations_type_label'.tr,
                labelStyle: TextStyle(
                  color: secondaryTextColor,
                  fontSize: scaleConfig.scaleText(12),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                  borderSide: BorderSide(
                    // ignore: deprecated_member_use
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                ),
              ),
              value: selectedType,
              dropdownColor: lighterColor,
              items: [
                DropdownMenuItem(
                  value: 'PREREQUISITE',
                  child: Text(
                    'add_relations_prerequisite'.tr,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: scaleConfig.scaleText(12),
                    ),
                  ),
                ),
              ],
              onChanged:
                  widget.isLoading
                      ? null
                      : (value) => setState(() => selectedType = value),
              validator:
                  (value) =>
                      value == null
                          ? 'add_relations_error_select_type'.tr
                          : null,
            ),
            SizedBox(height: scaleConfig.scale(20)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    widget.isLoading
                        ? null
                        : () {
                          if (selectedSubjectId != null &&
                              selectedType != null) {
                            widget.onAddRelationship(
                              selectedSubjectId!,
                              selectedType!,
                            );
                            _resetForm();
                          } else {
                            showFeedbackSnackbar(
                              context,
                              'add_relations_error_select_all'.tr,
                              isError: true,
                            );
                          }
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(
                    vertical: scaleConfig.scale(14),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'add_relations_add_button'.tr,
                  style: TextStyle(
                    fontSize: scaleConfig.scaleText(14),
                    color: Theme.of(context).scaffoldBackgroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
