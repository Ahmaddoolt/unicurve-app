import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/major.dart';
import 'package:unicurve/pages/uni_admin/providers/majors_provider.dart';

class EditMajorDialog extends ConsumerStatefulWidget {
  final Major major;
  final VoidCallback onSuccess;

  const EditMajorDialog({
    super.key,
    required this.major,
    required this.onSuccess,
  });

  @override
  EditMajorDialogState createState() => EditMajorDialogState();
}

class EditMajorDialogState extends ConsumerState<EditMajorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.major.name;
  }

  Future<void> _updateMajor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.major.id == null) {
        throw Exception('Cannot edit major: Missing ID or University ID');
      }

      await ref.read(majorsNotifierProvider.notifier).updateMajor(
            widget.major.id!,
            _nameController.text.trim(),
            widget.major.universityId,
            ref,
          );
      widget.onSuccess();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Major updated successfully'),
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = ScaleConfig(context);

    return AlertDialog(
      backgroundColor: AppColors.darkBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      title: Text(
        'Edit Major',
        style: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: scaleConfig.scaleText(18),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                style: TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontSize: scaleConfig.scaleText(14),
                ),
                decoration: InputDecoration(
                  labelText: 'Major Name',
                  labelStyle: TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: scaleConfig.scaleText(14),
                  ),
                  hintText: 'Enter major name',
                  hintStyle: TextStyle(
                    color: AppColors.darkTextSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.darkSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                    borderSide: const BorderSide(color: AppColors.primaryDark),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: scaleConfig.scale(16),
                    vertical: scaleConfig.scale(12),
                  ),
                ),
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'Please enter a major' : null,
                enabled: !_isLoading,
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: scaleConfig.scale(12)),
                Container(
                  padding: EdgeInsets.all(scaleConfig.scale(12)),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error,
                        color: AppColors.darkTextPrimary,
                        size: scaleConfig.scale(20),
                      ),
                      SizedBox(width: scaleConfig.scale(8)),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppColors.darkTextPrimary,
                            fontSize: scaleConfig.scaleText(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: scaleConfig.scaleText(14),
            ),
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : _updateMajor,
          child: _isLoading
              ? SizedBox(
                  height: scaleConfig.scale(16),
                  width: scaleConfig.scale(16),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Save',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: scaleConfig.scaleText(14),
                  ),
                ),
        ),
      ],
    );
  }
}
