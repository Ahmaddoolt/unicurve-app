// lib/pages/uni_admin/subjects/subjects_relationships/relationship_adder.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_button.dart';
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
  final _formKey = GlobalKey<FormState>();
  String? selectedSubjectId;
  String? selectedType;

  void _resetForm() {
    setState(() {
      selectedSubjectId = null;
      selectedType = null;
      _formKey.currentState?.reset();
    });
  }

  void _handleAddRelationship() {
    if (_formKey.currentState?.validate() ?? false) {
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
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryTextColor = theme.textTheme.bodyLarge?.color;
    final secondaryTextColor = theme.textTheme.bodyMedium?.color;

    // --- THE KEY FIX IS HERE: Replicating the exact style from your reference ---
    InputDecoration customInputDecoration({required String hint}) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: secondaryTextColor),
        filled: true,
        fillColor:
            isDarkMode ? Colors.black.withOpacity(0.2) : AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
              color: isDarkMode
                  ? AppColors.gradientBlueMid.withOpacity(0.5)
                  : Colors.grey.shade300,
              width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide:
              const BorderSide(color: AppColors.gradientBlueMid, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: selectedSubjectId,
            isExpanded: true,
            decoration: customInputDecoration(hint: 'select_hint'.tr),
            // --- Style fixes for the menu itself ---
            dropdownColor:
                isDarkMode ? const Color(0xFF2D3748) : theme.cardColor,
            style: TextStyle(color: primaryTextColor, fontSize: 16),
            icon: Icon(Icons.keyboard_arrow_down, color: primaryTextColor),
            items: widget.availableSubjects.map((subject) {
              return DropdownMenuItem<String>(
                value: subject['id'].toString(),
                child: Text(
                  '${subject['code']} - ${subject['name']}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: widget.isLoading
                ? null
                : (value) => setState(() => selectedSubjectId = value),
            validator: (value) =>
                value == null ? 'add_relations_error_select_subject'.tr : null,
          ),
          SizedBox(height: scaleConfig.scale(12)),
          DropdownButtonFormField<String>(
            value: selectedType,
            decoration:
                customInputDecoration(hint: 'add_relations_type_label'.tr),
            // --- Style fixes for the menu itself ---
            dropdownColor:
                isDarkMode ? const Color(0xFF2D3748) : theme.cardColor,
            style: TextStyle(color: primaryTextColor, fontSize: 16),
            icon: Icon(Icons.keyboard_arrow_down, color: primaryTextColor),
            items: [
              DropdownMenuItem(
                value: 'PREREQUISITE',
                child: Text('add_relations_prerequisite'.tr),
              ),
            ],
            onChanged: widget.isLoading
                ? null
                : (value) => setState(() => selectedType = value),
            validator: (value) =>
                value == null ? 'add_relations_error_select_type'.tr : null,
          ),
          SizedBox(height: scaleConfig.scale(20)),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              onPressed: widget.isLoading ? () {} : _handleAddRelationship,
              text: 'add_relations_add_button'.tr,
              gradient: widget.isLoading
                  ? AppColors.disabledGradient
                  : AppColors.primaryGradient,
            ),
          ),
        ],
      ),
    );
  }
}
