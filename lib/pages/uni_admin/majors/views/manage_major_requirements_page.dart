// lib/pages/uni_admin/majors/views/manage_major_requirements_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          _errorMessage = "Error fetching requirements: $e";
        });
      }
    }
  }

  Future<void> _showRequirementDialog({Map<String, dynamic>? existingRequirement}) async {
    final bool isEditMode = existingRequirement != null;
    final nameController = TextEditingController(text: isEditMode ? existingRequirement['requirement_name'] : '');
    final hoursController = TextEditingController(text: isEditMode ? existingRequirement['required_hours'].toString() : '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            isEditMode ? 'Edit Requirement' : 'Add Requirement',
            style: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold)
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Category Name', labelStyle: TextStyle(color: AppColors.darkTextSecondary)),
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                  validator: (v) => v!.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: hoursController,
                  decoration: const InputDecoration(labelText: 'Required Hours', labelStyle: TextStyle(color: AppColors.darkTextSecondary)),
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                   validator: (v) => v!.trim().isEmpty ? 'Hours are required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.accent)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
                    Navigator.pop(context);
                    _fetchRequirements();
                  }
                } catch(e) {
                   if (mounted) {
                     Navigator.pop(context);
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error)
                    );
                   }
                }
              },
              child: Text(isEditMode ? 'Save' : 'Add', style: const TextStyle(color: AppColors.darkBackground)),
            )
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(int requirementId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBackground,
        title: const Text('Confirm Deletion', style: TextStyle(color: AppColors.darkTextPrimary)),
        content: const Text('Are you sure you want to delete this requirement?', style: TextStyle(color: AppColors.darkTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.accent))
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _supabase.from('major_requirements').delete().eq('id', requirementId);
                _fetchRequirements();
              } catch(e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting: $e'), backgroundColor: AppColors.error)
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    
    // --- FIX IS HERE ---
    // Explicitly cast the value from the map to an int before adding.
    int totalHours = _requirements.fold(0, (sum, item) => sum + ((item['required_hours'] as int?) ?? 0));

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: CustomAppBar(
        title: 'Requirements for ${widget.major.name} $totalHours',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)))
              : RefreshIndicator(
                  onRefresh: _fetchRequirements,
                  color: AppColors.primary,
                  backgroundColor: AppColors.darkBackground,
                  child: _requirements.isEmpty 
                  ? Center(child: Text("No requirements added yet.\nTap the '+' button to begin.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.darkTextSecondary, fontSize: scaleConfig.scaleText(16))))
                  : ListView.builder(
                      padding: EdgeInsets.all(scaleConfig.scale(8)),
                      itemCount: _requirements.length,
                      itemBuilder: (context, index) {
                        final req = _requirements[index];
                        return Card(
                          color: AppColors.darkBackground,
                          margin: EdgeInsets.symmetric(vertical: scaleConfig.scale(4), horizontal: scaleConfig.scale(4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.primaryDark)
                          ),
                          child: ListTile(
                            title: Text(req['requirement_name'], style: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold)),
                            subtitle: Text('${req['required_hours']} hours', style: const TextStyle(color: AppColors.darkTextSecondary)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppColors.accent),
                                  tooltip: 'Edit Requirement',
                                  onPressed: () => _showRequirementDialog(existingRequirement: req),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                  tooltip: 'Delete Requirement',
                                  onPressed: () => _showDeleteConfirmation(req['id']),
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
        tooltip: 'Add Requirement',
        child: const Icon(Icons.add, color: AppColors.darkBackground),
      ),
    );
  }
}