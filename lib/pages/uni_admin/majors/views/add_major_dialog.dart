import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final universityId = widget.adminUniversity?['university_id'] as int? ??
        (await ref.read(adminUniversityProvider.future))?['university_id'] as int?;
    if (universityId == null) {
      setState(() => _errorMessage = 'No university assigned');
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
            content: const Text('Major added successfully'),
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
  Widget build(BuildContext context) {
    final scaleConfig = ScaleConfig(context);
    final adminUniversityAsync = widget.adminUniversity != null
        ? AsyncData(widget.adminUniversity)
        : ref.watch(adminUniversityProvider);

    return AlertDialog(
      backgroundColor: AppColors.darkBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      title: Text(
        'Add Major',
        style: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: scaleConfig.scaleText(18),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: adminUniversityAsync.when(
          data: (adminUniversity) => Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (adminUniversity != null) ...[
                  Text(
                    'University: ${adminUniversity['university_name']}',
                    style: TextStyle(
                      color: AppColors.darkTextPrimary,
                      fontSize: scaleConfig.scaleText(14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: scaleConfig.scale(12)),
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
                        value?.trim().isEmpty ?? true ? 'Please enter a major name' : null,
                    enabled: !_isLoading,
                  ),
                ],
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
                        Icon(Icons.error, color: AppColors.darkTextSecondary, size: scaleConfig.scale(20)),
                        SizedBox(width: scaleConfig.scale(8)),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: AppColors.darkTextSecondary,
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
          loading: () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: scaleConfig.scale(8)),
              Text(
                'Loading university...',
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: scaleConfig.scaleText(14),
                ),
              ),
            ],
          ),
          error: (e, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error: ${e.toString().replaceFirst('Exception: ', '')}',
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
        data: (adminUniversity) => [
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
            onPressed: _isLoading || adminUniversity == null ? null : _addMajor,
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
                    'Add',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: scaleConfig.scaleText(14),
                    ),
                  ),
          ),
        ],
        loading: () => [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: scaleConfig.scaleText(14),
              ),
            ),
          ),
        ],
        error: (_, __) => [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
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
