// lib/pages/uni_admin/subjects/edit_subject_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/scale_config.dart';

class EditSubjectDialog extends StatefulWidget {
  final Map<String, dynamic> subject;
  final Map<int, String> requirementsMap;
  final Function(Map<String, dynamic> updatedSubject) onSuccess;

  const EditSubjectDialog({
    super.key,
    required this.subject,
    required this.requirementsMap,
    required this.onSuccess,
  });

  @override
  EditSubjectDialogState createState() => EditSubjectDialogState();
}

class EditSubjectDialogState extends State<EditSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _hoursController;
  late TextEditingController _descriptionController;
  late bool _isOpen;
  int? _typeId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject['name']);
    _codeController = TextEditingController(text: widget.subject['code']);
    _hoursController =
        TextEditingController(text: widget.subject['hours'].toString());
    _descriptionController =
        TextEditingController(text: widget.subject['description'] ?? '');
    _isOpen = widget.subject['is_open'] ?? false;
    _typeId = widget.subject['type'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _hoursController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedData = {
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim(),
        'hours': int.tryParse(_hoursController.text.trim()) ?? 0,
        'description': _descriptionController.text.trim(),
        'is_open': _isOpen,
        'type': _typeId,
      };

      final response = await _supabase
          .from('subjects')
          .update(updatedData)
          .eq('id', widget.subject['id'])
          .select()
          .single();

      if (mounted) {
        widget.onSuccess(response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'edit_subject_error_update'.trParams({'error': e.toString()})),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaleConfig = context.scaleConfig;
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryTextColor = theme.textTheme.bodyLarge?.color;
    final secondaryTextColor = theme.textTheme.bodyMedium?.color;

    InputDecoration customInputDecoration({required String labelText}) {
      return InputDecoration(
        labelText: labelText,
        labelStyle: theme.textTheme.labelLarge,
        filled: true,
        fillColor: isDarkMode
            ? Colors.black.withOpacity(0.25)
            : theme.inputDecorationTheme.fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: isDarkMode
              ? BorderSide(color: Colors.white.withOpacity(0.2))
              : BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: GlassCard(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('edit_subject_dialog_title'.tr,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontSize: scaleConfig.scaleText(20))),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: customInputDecoration(
                        labelText: 'add_subject_name_label'.tr),
                    style: TextStyle(color: primaryTextColor),
                    validator: (v) =>
                        v!.trim().isEmpty ? 'error_field_required'.tr : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeController,
                    decoration: customInputDecoration(
                        labelText: 'add_subject_code_label'.tr),
                    style: TextStyle(color: primaryTextColor),
                    validator: (v) =>
                        v!.trim().isEmpty ? 'error_field_required'.tr : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _hoursController,
                    decoration: customInputDecoration(
                        labelText: 'add_subject_hours_label'.tr),
                    style: TextStyle(color: primaryTextColor),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        v!.trim().isEmpty ? 'error_field_required'.tr : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _typeId,
                    items: widget.requirementsMap.entries
                        .map((entry) => DropdownMenuItem<int>(
                            value: entry.key, child: Text(entry.value)))
                        .toList(),
                    onChanged: (value) => setState(() => _typeId = value),
                    decoration: customInputDecoration(
                        labelText: 'add_subject_req_type_label'.tr),
                    dropdownColor:
                        isDarkMode ? const Color(0xFF2D3748) : theme.cardColor,
                    style: TextStyle(color: primaryTextColor, fontSize: 16),
                    icon: Icon(Icons.keyboard_arrow_down,
                        color: primaryTextColor),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('add_subject_is_open_label'.tr,
                        style: theme.textTheme.bodyLarge),
                    value: _isOpen,
                    onChanged: (value) => setState(() => _isOpen = value),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    tileColor: theme.colorScheme.surface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        child: Text('cancel'.tr,
                            style: TextStyle(color: secondaryTextColor)),
                      ),
                      const SizedBox(width: 8),
                      CustomButton(
                        // --- THE FIX IS HERE ---
                        onPressed: _isLoading ? () {} : () => _saveChanges(),
                        text: 'save_button'.tr,
                        gradient: _isLoading
                            ? AppColors.disabledGradient
                            : AppColors.primaryGradient,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
