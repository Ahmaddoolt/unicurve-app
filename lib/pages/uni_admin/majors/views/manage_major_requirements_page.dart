import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
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
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: darkerColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            isEditMode ? 'req_dialog_edit_title'.tr : 'req_dialog_add_title'.tr,
            style: TextStyle(
              color: primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'req_dialog_name_label'.tr,
                    labelStyle: TextStyle(color: secondaryTextColor),
                  ),
                  style: TextStyle(color: primaryTextColor),
                  validator:
                      (v) =>
                          v!.trim().isEmpty
                              ? 'req_dialog_error_name_empty'.tr
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: hoursController,
                  decoration: InputDecoration(
                    labelText: 'req_dialog_hours_label'.tr,
                    labelStyle: TextStyle(color: secondaryTextColor),
                  ),
                  style: TextStyle(color: primaryTextColor),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator:
                      (v) =>
                          v!.trim().isEmpty
                              ? 'req_dialog_error_hours_empty'.tr
                              : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'cancel'.tr,
                style: const TextStyle(color: AppColors.accent),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
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
                    await _supabase.from('major_requirements').insert(data);
                  }

                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                    _fetchRequirements();
                  }
                } catch (e) {
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'error_generic'.trParams({'error': e.toString()}),
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: Text(
                isEditMode ? 'save_button'.tr : 'add_button'.tr,
                style: const TextStyle(color: AppColors.darkBackground),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(int requirementId) async {
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: darkerColor,
            title: Text(
              'confirm_deletion_title'.tr,
              style: TextStyle(color: primaryTextColor),
            ),
            content: Text(
              'req_delete_confirm_message'.tr,
              style: TextStyle(color: secondaryTextColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'cancel'.tr,
                  style: const TextStyle(color: AppColors.accent),
                ),
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
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'req_error_deleting'.trParams({
                            'error': e.toString(),
                          }),
                        ),
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
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;

    int totalHours = _requirements.fold(
      0,
      (sum, item) => sum + ((item['required_hours'] as int?) ?? 0),
    );
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: lighterColor,
      appBar: CustomAppBar(
        title: 'req_page_title'.trParams({
          'majorName': widget.major.name,
          'totalHours': totalHours.toString(),
        }),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
              : _errorMessage != null
              ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchRequirements,
                color: AppColors.primary,
                backgroundColor: darkerColor,
                child:
                    _requirements.isEmpty
                        ? Center(
                          child: Text(
                            'req_empty_list_prompt'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: scaleConfig.scaleText(16),
                            ),
                          ),
                        )
                        : ListView.builder(
                          padding: EdgeInsets.all(scaleConfig.scale(8)),
                          itemCount: _requirements.length,
                          itemBuilder: (context, index) {
                            final req = _requirements[index];
                            return Card(
                              color: darkerColor,
                              margin: EdgeInsets.symmetric(
                                vertical: scaleConfig.scale(4),
                                horizontal: scaleConfig.scale(4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  req['requirement_name'],
                                  style: TextStyle(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'hours_label'.trParams({
                                    'hours': req['required_hours'].toString(),
                                  }),
                                  style: TextStyle(color: secondaryTextColor),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: AppColors.accent,
                                      ),
                                      tooltip: 'req_edit_tooltip'.tr,
                                      onPressed:
                                          () => _showRequirementDialog(
                                            existingRequirement: req,
                                          ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.error,
                                      ),
                                      tooltip: 'req_delete_tooltip'.tr,
                                      onPressed:
                                          () => _showDeleteConfirmation(
                                            req['id'],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRequirementDialog(),
        backgroundColor: AppColors.primary,
        tooltip: 'req_add_tooltip'.tr,
        child: Icon(Icons.add, color: darkerColor),
      ),
    );
  }
}
