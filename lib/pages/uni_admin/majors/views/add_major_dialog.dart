import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/major.dart';
import 'package:unicurve/pages/uni_admin/providers/admin_university_provider.dart';
import 'package:unicurve/pages/uni_admin/providers/majors_provider.dart';

class AddMajorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? adminUniversity;
  final VoidCallback onSuccess;

  const AddMajorDialog({
    super.key,
    this.adminUniversity,
    required this.onSuccess,
  });

  @override
  AddMajorDialogState createState() => AddMajorDialogState();
}

class AddMajorDialogState extends ConsumerState<AddMajorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addMajor() async {
    if (!_formKey.currentState!.validate()) return;

    final universityId =
        widget.adminUniversity?['university_id'] as int? ??
        (await ref.read(adminUniversityProvider.future))?['university_id']
            as int?;
    if (universityId == null) {
      setState(() => _errorMessage = 'add_major_error_no_uni'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final major = Major(
        name: _nameController.text.trim(),
        universityId: universityId,
      );
      await ref.read(majorsNotifierProvider.notifier).addMajor(major, ref);
      widget.onSuccess();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('add_major_success'.tr),
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
    final adminUniversityAsync =
        widget.adminUniversity != null
            ? AsyncData(widget.adminUniversity)
            : ref.watch(adminUniversityProvider);
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return AlertDialog(
      backgroundColor: darkerColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      title: Text(
        'add_major_title'.tr,
        style: TextStyle(
          color: primaryTextColor,
          fontSize: scaleConfig.scaleText(18),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: adminUniversityAsync.when(
          data:
              (adminUniversity) => Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (adminUniversity != null) ...[
                      Text(
                        'add_major_university_label'.trParams({
                          'uniName': adminUniversity['university_name'],
                        }),
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: scaleConfig.scaleText(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: scaleConfig.scale(12)),
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
                            borderRadius: BorderRadius.circular(
                              scaleConfig.scale(8),
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              scaleConfig.scale(8),
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.primaryDark,
                            ),
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
                    ],
                    if (_errorMessage != null) ...[
                      SizedBox(height: scaleConfig.scale(12)),
                      Container(
                        padding: EdgeInsets.all(scaleConfig.scale(12)),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(
                            scaleConfig.scale(8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error,
                              color: secondaryTextColor,
                              size: scaleConfig.scale(20),
                            ),
                            SizedBox(width: scaleConfig.scale(8)),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: secondaryTextColor,
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
          loading:
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: scaleConfig.scale(8)),
                  Text(
                    'add_major_loading_uni'.tr,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: scaleConfig.scaleText(14),
                    ),
                  ),
                ],
              ),
          error:
              (e, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'error_generic'.trParams({
                      'error': e.toString().replaceFirst('Exception: ', ''),
                    }),
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: scaleConfig.scaleText(14),
                    ),
                  ),
                ],
              ),
        ),
      ),
      actions: adminUniversityAsync.when(
        data:
            (adminUniversity) => [
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
                onPressed:
                    _isLoading || adminUniversity == null ? null : _addMajor,
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
                          'add_button'.tr,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: scaleConfig.scaleText(14),
                          ),
                        ),
              ),
            ],
        loading:
            () => [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'close_button'.tr,
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: scaleConfig.scaleText(14),
                  ),
                ),
              ),
            ],
        error:
            (_, __) => [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'close_button'.tr,
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: scaleConfig.scaleText(14),
                  ),
                ),
              ),
            ],
      ),
    );
  }
}
