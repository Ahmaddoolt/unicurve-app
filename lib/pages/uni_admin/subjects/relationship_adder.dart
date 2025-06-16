import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';
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
  // ignore: library_private_types_in_public_api
  _RelationshipAdderState createState() => _RelationshipAdderState();
}

class _RelationshipAdderState extends State<RelationshipAdder> {
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

    return Card(
      elevation: 6,
      color: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
      ),
      child: Padding(
        padding: EdgeInsets.all(scaleConfig.scale(16)),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Subject',
                labelStyle: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: scaleConfig.scaleText(12),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                  borderSide: BorderSide(
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                ),
              ),
              dropdownColor: AppColors.darkSurface,
              items:
                  widget.availableSubjects.map((subject) {
                    return DropdownMenuItem<String>(
                      value: subject['id'],
                      child: Text(
                        '${subject['name']}',
                        style: TextStyle(
                          color: AppColors.darkTextPrimary,
                          fontSize: scaleConfig.scaleText(10),
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
                  (value) => value == null ? 'Please select a subject' : null,
            ),
            SizedBox(height: scaleConfig.scale(12)),
            // --- MODIFIED DROPDOWN ---
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Type',
                labelStyle: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: scaleConfig.scaleText(12),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                  borderSide: BorderSide(
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                ),
              ),
              dropdownColor: AppColors.darkSurface,
              items: const [
                DropdownMenuItem(
                  value: 'PREREQUISITE',
                  child: Text(
                    'Prerequisite',
                    style: TextStyle(
                      color: AppColors.darkTextPrimary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
              onChanged:
                  widget.isLoading
                      ? null
                      : (value) => setState(() => selectedType = value),
              validator:
                  (value) => value == null ? 'Please select a type' : null,
            ),
            SizedBox(height: scaleConfig.scale(12)),
            ElevatedButton(
              onPressed:
                  widget.isLoading
                      ? null
                      : () {
                        if (selectedSubjectId != null && selectedType != null) {
                          widget.onAddRelationship(
                            selectedSubjectId!,
                            selectedType!,
                          );
                          _resetForm();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please select both subject and relationship type',
                                style: TextStyle(
                                  color: AppColors.darkTextPrimary,
                                  fontSize: scaleConfig.scaleText(14),
                                ),
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.darkTextPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: scaleConfig.scale(8),
                  vertical: scaleConfig.scale(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                ),
                elevation: 2,
              ),
              child: Text(
                'Add',
                style: TextStyle(
                  fontSize: scaleConfig.scaleText(14),
                  color: AppColors.darkBackground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}