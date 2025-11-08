// lib/pages/uni_admin/majors/views/manage_major_requirements_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_floadt_action_button.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/glass_loading_overlay.dart'; // --- FIX: Import the overlay ---
import 'package:unicurve/core/utils/gradient_icon.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/major.dart';

class ManageMajorRequirementsPage extends StatefulWidget {
  final Major major;
  const ManageMajorRequirementsPage({super.key, required this.major});

  @override
  State<ManageMajorRequirementsPage> createState() =>
      _ManageMajorRequirementsPageState();
}

class _ManageMajorRequirementsPageState
    extends State<ManageMajorRequirementsPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _requirements = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRequirements();
  }

  Future<void> _fetchRequirements() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _supabase
          .from('major_requirements')
          .select('id, requirement_name, required_hours')
          .eq('major_id', widget.major.id!)
          .order('id', ascending: true);
      if (mounted) {
        setState(() {
          _requirements = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'req_error_fetching'.trParams({
            'error': e.toString(),
          });
        });
      }
    }
  }

  Future<void> _showRequirementDialog({
    Map<String, dynamic>? existingRequirement,
  }) async {
    final bool isEditMode = existingRequirement != null;
    final nameController = TextEditingController(
      text: isEditMode ? existingRequirement['requirement_name'] : '',
    );
    final hoursController = TextEditingController(
      text: isEditMode ? existingRequirement['required_hours'].toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final scaleConfig = context.scaleConfig;
        final primaryTextColor = theme.textTheme.bodyLarge?.color;
        final secondaryTextColor = theme.textTheme.bodyMedium?.color;

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
          labelStyle: TextStyle(color: secondaryTextColor),
        );

        return AlertDialog(
          backgroundColor: theme.brightness == Brightness.dark
              ? Colors.transparent
              : theme.cardColor,
          elevation: 0,
          contentPadding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: GlassCard(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditMode
                          ? 'req_dialog_edit_title'.tr
                          : 'req_dialog_add_title'.tr,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: scaleConfig.scaleText(20),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nameController,
                      decoration: customInputDecoration.copyWith(
                          labelText: 'req_dialog_name_label'.tr),
                      style: TextStyle(color: primaryTextColor),
                      validator: (v) => v!.trim().isEmpty
                          ? 'req_dialog_error_name_empty'.tr
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: hoursController,
                      decoration: customInputDecoration.copyWith(
                          labelText: 'req_dialog_hours_label'.tr),
                      style: TextStyle(color: primaryTextColor),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => v!.trim().isEmpty
                          ? 'req_dialog_error_hours_empty'.tr
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'cancel'.tr,
                            style: TextStyle(color: secondaryTextColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CustomButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final data = {
                              'major_id': widget.major.id,
                              'requirement_name': nameController.text.trim(),
                              'required_hours': int.parse(hoursController.text),
                            };
                            try {
                              if (isEditMode) {
                                await _supabase
                                    .from('major_requirements')
                                    .update(data)
                                    .eq('id', existingRequirement['id']);
                              } else {
                                await _supabase
                                    .from('major_requirements')
                                    .insert(data);
                              }
                              if (mounted) {
                                Navigator.pop(context);
                                _fetchRequirements();
                              }
                            } catch (e) {
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('error_generic'
                                        .trParams({'error': e.toString()})),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          text: isEditMode ? 'save_button'.tr : 'add_button'.tr,
                          gradient: AppColors.primaryGradient,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(int requirementId) async {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final primaryTextColor = theme.textTheme.bodyLarge?.color;
        final secondaryTextColor = theme.textTheme.bodyMedium?.color;

        return AlertDialog(
          backgroundColor: theme.brightness == Brightness.dark
              ? Colors.transparent
              : theme.cardColor,
          elevation: 0,
          contentPadding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: GlassCard(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('confirm_deletion_title'.tr,
                      style: TextStyle(
                          color: primaryTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                  const SizedBox(height: 16),
                  Text('req_delete_confirm_message'.tr,
                      style: TextStyle(color: secondaryTextColor)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('cancel'.tr,
                            style: TextStyle(color: secondaryTextColor)),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await _supabase
                                .from('major_requirements')
                                .delete()
                                .eq('id', requirementId);
                            _fetchRequirements();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('req_error_deleting'
                                    .trParams({'error': e.toString()})),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                        child: Text(
                          'delete_button'.tr,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    int totalHours = _requirements.fold(
      0,
      (sum, item) => sum + ((item['required_hours'] as int?) ?? 0),
    );

    final appBar = CustomAppBar(
      useGradient: !isDarkMode,
      title: 'req_page_title'.trParams({
        'majorName': widget.major.name,
        'totalHours': totalHours.toString(),
      }),
    );

    final bodyContent = GlassLoadingOverlay(
      isLoading: _isLoading,
      child: _errorMessage != null
          ? Center(
              child: Text(_errorMessage!,
                  style: const TextStyle(color: AppColors.error)))
          : RefreshIndicator(
              onRefresh: _fetchRequirements,
              color: AppColors.primary,
              child: _requirements.isEmpty && !_isLoading
                  ? Center(
                      child: Text(
                        'req_empty_list_prompt'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: scaleConfig.scaleText(16),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(scaleConfig.scale(16)),
                      itemCount: _requirements.length,
                      itemBuilder: (context, index) {
                        final req = _requirements[index];
                        return _RequirementListTile(
                          requirement: req,
                          onEdit: () =>
                              _showRequirementDialog(existingRequirement: req),
                          onDelete: () => _showDeleteConfirmation(req['id']),
                        );
                      },
                    ),
            ),
    );

    if (isDarkMode) {
      return GradientScaffold(
        appBar: appBar,
        body: bodyContent,
        floatingActionButton:
            CustomFAB(onPressed: () => _showRequirementDialog()),
      );
    } else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        body: bodyContent,
        floatingActionButton:
            CustomFAB(onPressed: () => _showRequirementDialog()),
      );
    }
  }
}

class _RequirementListTile extends StatelessWidget {
  final Map<String, dynamic> requirement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RequirementListTile({
    required this.requirement,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);

    return GlassCard(
      margin: EdgeInsets.only(bottom: scaleConfig.scale(12)),
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: scaleConfig.scale(16),
          vertical: scaleConfig.scale(8),
        ),
        leading: GradientIcon(
          icon: Icons.rule_folder_outlined,
          size: scaleConfig.scale(30),
        ),
        title: Text(
          requirement['requirement_name'],
          style:
              theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'hours_label'.trParams(
              {'hours': (requirement['required_hours'] ?? 0).toString()}),
          style: theme.textTheme.bodyMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  color: theme.textTheme.bodyMedium?.color),
              tooltip: 'req_edit_tooltip'.tr,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'req_delete_tooltip'.tr,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
