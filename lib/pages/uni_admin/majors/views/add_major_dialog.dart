// lib/pages/uni_admin/majors/views/add_major_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/glass_card.dart';
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

    final universityId = widget.adminUniversity?['university_id'] as int? ??
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
            backgroundColor: AppColors.primary,
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
          () => _errorMessage = 'error_generic'.trParams(
              {'error': e.toString().replaceFirst('Exception: ', '')}),
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
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    final adminUniversityAsync = widget.adminUniversity != null
        ? AsyncData(widget.adminUniversity)
        : ref.watch(adminUniversityProvider);
    Color? primaryTextColor = theme.textTheme.bodyLarge?.color;
    Color? secondaryTextColor = theme.textTheme.bodyMedium?.color;

    final customInputDecoration = InputDecoration(
      filled: true,
      fillColor: theme.brightness == Brightness.dark
          ? Colors.black.withOpacity(0.2)
          : AppColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
      labelStyle: TextStyle(color: secondaryTextColor),
      hintStyle: TextStyle(color: secondaryTextColor),
    );

    return AlertDialog(
      backgroundColor: theme.brightness == Brightness.dark
          ? Colors.transparent
          : theme.cardColor,
      elevation: 0,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: GlassCard(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'add_major_title'.tr,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: scaleConfig.scaleText(20),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              adminUniversityAsync.when(
                data: (adminUniversity) => Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (adminUniversity != null) ...[
                        Text(
                          'add_major_university_label'.trParams({
                            'uniName': adminUniversity['university_name'],
                          }),
                          style: TextStyle(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: scaleConfig.scale(12)),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: primaryTextColor),
                          decoration: customInputDecoration.copyWith(
                            labelText: 'add_major_name_label'.tr,
                            hintText: 'add_major_name_hint'.tr,
                          ),
                          validator: (value) => value?.trim().isEmpty ?? true
                              ? 'add_major_error_name_empty'.tr
                              : null,
                          enabled: !_isLoading,
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        SizedBox(height: scaleConfig.scale(16)),
                        Container(
                          padding: EdgeInsets.all(scaleConfig.scale(12)),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(scaleConfig.scale(8)),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error,
                                  color: AppColors.error, size: 20),
                              SizedBox(width: scaleConfig.scale(8)),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style:
                                      const TextStyle(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Text(
                    'error_generic'.trParams({'error': e.toString()}),
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              adminUniversityAsync.when(
                data: (adminUniversity) => Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: Text(
                        'cancel'.tr,
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else
                      CustomButton(
                        // --- THE FIX IS HERE ---
                        // We create the callback. If the condition to disable is met,
                        // the callback is an empty function. Otherwise, it calls _addMajor.
                        // The button widget will handle the visual disabled state.
                        onPressed: adminUniversity == null || _isLoading
                            ? () {} // Provide an empty, non-null function
                            : _addMajor,
                        text: 'add_button'.tr,
                        gradient: adminUniversity == null || _isLoading
                            ? AppColors
                                .disabledGradient // Optional: show a disabled gradient
                            : AppColors.primaryGradient,
                      ),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
