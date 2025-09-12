import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateMajor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.major.id == null) {
        throw Exception('edit_major_error_missing_id'.tr);
      }

      await ref
          .read(majorsNotifierProvider.notifier)
          .updateMajor(
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
            content: Text('edit_major_success'.tr),
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
        setState(
          () =>
              _errorMessage = 'error_generic'.trParams({
                'error': e.toString().replaceFirst('Exception: ', ''),
              }),
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
    final scaleConfig = ScaleConfig(context);
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return AlertDialog(
      backgroundColor: darkerColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      title: Text(
        'edit_major_title'.tr,
        style: TextStyle(
          color: primaryTextColor,
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
                  color: primaryTextColor,
                  fontSize: scaleConfig.scaleText(14),
                ),
                decoration: InputDecoration(
                  labelText: 'add_major_name_label'.tr,
                  labelStyle: TextStyle(
                    color: secondaryTextColor,
                    fontSize: scaleConfig.scaleText(14),
                  ),
                  hintText: 'add_major_name_hint'.tr,
                  hintStyle: TextStyle(color: secondaryTextColor),
                  filled: true,
                  fillColor: lighterColor,
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
                validator:
                    (value) =>
                        value?.trim().isEmpty ?? true
                            ? 'add_major_error_name_empty'.tr
                            : null,
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
                        color: primaryTextColor,
                        size: scaleConfig.scale(20),
                      ),
                      SizedBox(width: scaleConfig.scale(8)),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: primaryTextColor,
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
            'cancel'.tr,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: scaleConfig.scaleText(14),
            ),
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : _updateMajor,
          child:
              _isLoading
                  ? SizedBox(
                    height: scaleConfig.scale(16),
                    width: scaleConfig.scale(16),
                    child: const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  )
                  : Text(
                    'save_button'.tr,
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
