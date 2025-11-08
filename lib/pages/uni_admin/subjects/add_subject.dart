// lib/pages/uni_admin/subjects/add_subject.dart

import 'dart:ui'; // --- FIX: Import for ImageFilter ---
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/glass_loading_overlay.dart'; // --- FIX: Import the new widget ---
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/subject.dart';
import 'package:unicurve/pages/uni_admin/providers/admin_university_provider.dart';
import 'package:unicurve/pages/uni_admin/subjects/subjects_relationships/add_subjects_relations.dart';

class AddSubjectBasicPage extends ConsumerStatefulWidget {
  const AddSubjectBasicPage({super.key});

  @override
  AddSubjectBasicPageState createState() => AddSubjectBasicPageState();
}

class AddSubjectBasicPageState extends ConsumerState<AddSubjectBasicPage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _hours = 1;
  bool _isOpen = false;
  int? _majorId;
  int _level = 1;
  int? _selectedRequirementId;

  List<Map<String, dynamic>> _majors = [];
  List<Map<String, dynamic>> _majorRequirements = [];

  bool _isLoadingMajors = true;
  bool _isLoadingRequirements = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  int? _universityId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMajors();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchMajors() async {
    setState(() {
      _isLoadingMajors = true;
      _errorMessage = null;
    });
    try {
      final adminUniversity = await ref.read(adminUniversityProvider.future);
      if (adminUniversity == null || adminUniversity['university_id'] == null) {
        throw Exception('University not found. Please go back and try again.');
      }
      final universityId = adminUniversity['university_id'];

      final response = await supabase
          .from('majors')
          .select('id, name')
          .eq('university_id', universityId);

      if (mounted) {
        setState(() {
          _universityId = universityId;
          _majors = List<Map<String, dynamic>>.from(response);
          _isLoadingMajors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError(
          'add_subject_error_fetch_majors'.trParams({'error': e.toString()}),
        );
        setState(() => _isLoadingMajors = false);
      }
    }
  }

  Future<void> _fetchRequirementsForMajor(int majorId) async {
    setState(() {
      _isLoadingRequirements = true;
      _majorRequirements = [];
      _selectedRequirementId = null;
    });
    try {
      final response = await supabase
          .from('major_requirements')
          .select('id, requirement_name')
          .eq('major_id', majorId);

      if (mounted) {
        setState(() {
          _majorRequirements = List<Map<String, dynamic>>.from(response);
          _isLoadingRequirements = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError(
          'add_subject_error_fetch_reqs'.trParams({'error': e.toString()}),
        );
        setState(() => _isLoadingRequirements = false);
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _showError('add_subject_error_fill_fields'.tr);
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);
    _errorMessage = null;

    try {
      final subject = Subject(
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        hours: _hours,
        isOpen: _isOpen,
        majorId: _majorId,
        level: _level,
        type: _selectedRequirementId,
      );

      final response = await supabase
          .from('subjects')
          .insert(subject.toMap())
          .select()
          .single();

      if (mounted) {
        final newSubject = Subject.fromMap(response);

        final bool? success = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => AddSubjectRelationsPage(
              subject: newSubject,
              universityId: _universityId!,
            ),
          ),
        );

        if (success == true && mounted) {
          Navigator.of(context).pop(true);
        } else if (success == false && mounted) {
          Navigator.of(context).pop(false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(
          'add_subject_error_submit'.trParams({'error': e.toString()}),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBar = CustomAppBar(
      title: 'add_subject_page_title'.tr,
      centerTitle: true,
      useGradient: !isDarkMode,
    );

    final bodyContent = GlassLoadingOverlay(
      isLoading: _isLoadingMajors,
      child: SingleChildScrollView(
        // The content is visible but non-interactive when loading
        physics: _isLoadingMajors ? const NeverScrollableScrollPhysics() : null,
        padding: EdgeInsets.all(scaleConfig.scale(16)),
        child: GlassCard(
          child: Padding(
            padding: EdgeInsets.all(scaleConfig.scale(16)),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'add_subject_section_details'.tr,
                    scaleConfig,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _codeController,
                    label: 'add_subject_code_label'.tr,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    label: 'add_subject_name_label'.tr,
                  ),
                  const SizedBox(height: 16),
                  _buildMajorDropdown(),
                  const SizedBox(height: 16),
                  if (_majorId != null) _buildRequirementTypeDropdown(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildHoursDropdown()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildLevelDropdown()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'add_subject_desc_label'.tr,
                    maxLines: 3,
                    isRequired: false,
                  ),
                  const SizedBox(height: 8),
                  _buildIsOpenSwitch(),
                  if (_errorMessage != null) _buildErrorMessageWidget(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (isDarkMode) {
      return GradientScaffold(appBar: appBar, body: bodyContent);
    } else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        body: bodyContent,
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
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

  Widget _buildSectionHeader(String title, ScaleConfig scaleConfig) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontSize: scaleConfig.scaleText(18)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: _inputDecoration(label),
      maxLines: maxLines,
      validator: isRequired
          ? (value) => value!.trim().isEmpty ? 'error_field_required'.tr : null
          : null,
      enabled: !_isSubmitting,
    );
  }

  Widget _buildMajorDropdown() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return DropdownButtonFormField<int>(
      value: _majorId,
      decoration: _inputDecoration('add_subject_major_label'.tr),
      style: theme.textTheme.bodyLarge,
      dropdownColor: isDarkMode ? const Color(0xFF2D3748) : theme.cardColor,
      icon: Icon(Icons.keyboard_arrow_down,
          color: theme.textTheme.bodyMedium?.color),
      items: _majors.map((major) {
        return DropdownMenuItem<int>(
          value: major['id'] as int,
          child: Text(major['name']),
        );
      }).toList(),
      onChanged: _isSubmitting
          ? null
          : (value) {
              if (value != null && value != _majorId) {
                setState(() => _majorId = value);
                _fetchRequirementsForMajor(value);
              }
            },
      validator: (value) =>
          value == null ? 'add_subject_error_select_major'.tr : null,
    );
  }

  Widget _buildRequirementTypeDropdown() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    if (_isLoadingRequirements) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return DropdownButtonFormField<int>(
      value: _selectedRequirementId,
      decoration: _inputDecoration('add_subject_req_type_label'.tr),
      hint: _majorRequirements.isEmpty
          ? Text('add_subject_no_reqs'.tr, style: theme.textTheme.labelLarge)
          : null,
      style: theme.textTheme.bodyLarge,
      dropdownColor: isDarkMode ? const Color(0xFF2D3748) : theme.cardColor,
      icon: Icon(Icons.keyboard_arrow_down,
          color: theme.textTheme.bodyMedium?.color),
      items: _majorRequirements.map((req) {
        return DropdownMenuItem<int>(
          value: req['id'] as int,
          child: Text(req['requirement_name']),
        );
      }).toList(),
      onChanged: _isSubmitting || _majorRequirements.isEmpty
          ? null
          : (value) => setState(() => _selectedRequirementId = value),
      validator: (value) =>
          value == null ? 'add_subject_error_select_req'.tr : null,
    );
  }

  Widget _buildHoursDropdown() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return DropdownButtonFormField<int>(
      value: _hours,
      decoration: _inputDecoration('add_subject_hours_label'.tr),
      style: theme.textTheme.bodyLarge,
      dropdownColor: isDarkMode ? const Color(0xFF2D3748) : theme.cardColor,
      icon: Icon(Icons.keyboard_arrow_down,
          color: theme.textTheme.bodyMedium?.color),
      items: List.generate(6, (i) => i + 1).map((h) {
        return DropdownMenuItem<int>(
          value: h,
          child: Text('add_subject_hours_unit'.trParams({'count': '$h'})),
        );
      }).toList(),
      onChanged: _isSubmitting ? null : (v) => setState(() => _hours = v!),
      validator: (v) => v == null ? 'error_field_required'.tr : null,
    );
  }

  Widget _buildLevelDropdown() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return DropdownButtonFormField<int>(
      value: _level,
      decoration: _inputDecoration('add_subject_level_label'.tr),
      style: theme.textTheme.bodyLarge,
      dropdownColor: isDarkMode ? const Color(0xFF2D3748) : theme.cardColor,
      icon: Icon(Icons.keyboard_arrow_down,
          color: theme.textTheme.bodyMedium?.color),
      items: List.generate(5, (i) => i + 1).map((l) {
        return DropdownMenuItem<int>(
          value: l,
          child: Text('add_subject_level_unit'.trParams({'level': '$l'})),
        );
      }).toList(),
      onChanged: _isSubmitting ? null : (v) => setState(() => _level = v!),
      validator: (v) => v == null ? 'error_field_required'.tr : null,
    );
  }

  Widget _buildIsOpenSwitch() {
    final theme = Theme.of(context);
    return SwitchListTile(
      title: Text('add_subject_is_open_label'.tr,
          style: theme.textTheme.bodyLarge),
      value: _isOpen,
      onChanged: _isSubmitting ? null : (v) => setState(() => _isOpen = v),
      activeColor: AppColors.primary,
      inactiveThumbColor: theme.textTheme.bodyMedium?.color,
      tileColor: theme.colorScheme.surface.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        onPressed: _isSubmitting ? () {} : () => _submitForm(),
        text: 'add_subject_continue_button'.tr,
        gradient: _isSubmitting
            ? AppColors.disabledGradient
            : AppColors.primaryGradient,
      ),
    );
  }

  Widget _buildErrorMessageWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
