import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
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
      final adminUniversity = ref.read(adminUniversityProvider).value;
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
    if (_universityId == null) {
      _showError('add_subject_error_no_university'.tr);
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

      final response =
          await supabase
              .from('subjects')
              .insert(subject.toMap())
              .select()
              .single();

      if (mounted) {
        final newSubject = Subject.fromMap(response);

        final bool? success = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder:
                (context) => AddSubjectRelationsPage(
                  subject: newSubject,
                  universityId: _universityId!,
                ),
          ),
        );

        if (success == true && mounted) {
          Navigator.of(context).pop(true);
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
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: lighterColor,
      appBar: CustomAppBar(
        title: 'add_subject_page_title'.tr,
        centerTitle: true,
        backgroundColor: darkerColor,
      ),
      body:
          _isLoadingMajors
              ? _buildLoadingIndicator('add_subject_loading_majors'.tr)
              : SingleChildScrollView(
                padding: EdgeInsets.all(scaleConfig.scale(16)),
                child: Card(
                  color: darkerColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(scaleConfig.scale(16)),
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  elevation: 4,
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
  }

  Widget _buildSectionHeader(String title, ScaleConfig scaleConfig) {
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Text(
      title,
      style: TextStyle(
        color: primaryTextColor,
        fontSize: scaleConfig.scaleText(18),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    return TextFormField(
      controller: controller,
      style: TextStyle(color: primaryTextColor),
      decoration: _inputDecoration(label),
      maxLines: maxLines,
      validator:
          isRequired
              ? (value) =>
                  value!.trim().isEmpty ? 'error_field_required'.tr : null
              : null,
      enabled: !_isSubmitting,
    );
  }

  Widget _buildMajorDropdown() {
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    return DropdownButtonFormField<int>(
      value: _majorId,
      decoration: _inputDecoration('add_subject_major_label'.tr),
      items:
          _majors.map((major) {
            return DropdownMenuItem<int>(
              value: major['id'] as int,
              child: Text(
                major['name'],
                style: TextStyle(color: primaryTextColor),
              ),
            );
          }).toList(),
      onChanged:
          _isSubmitting
              ? null
              : (value) {
                if (value != null && value != _majorId) {
                  setState(() => _majorId = value);
                  _fetchRequirementsForMajor(value);
                }
              },
      validator:
          (value) => value == null ? 'add_subject_error_select_major'.tr : null,
      dropdownColor: darkerColor,
    );
  }

  Widget _buildRequirementTypeDropdown() {
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    if (_isLoadingRequirements) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return DropdownButtonFormField<int>(
      value: _selectedRequirementId,
      decoration: _inputDecoration('add_subject_req_type_label'.tr),
      hint:
          _majorRequirements.isEmpty
              ? Text(
                'add_subject_no_reqs'.tr,
                style: TextStyle(color: secondaryTextColor),
              )
              : null,
      items:
          _majorRequirements.map((req) {
            return DropdownMenuItem<int>(
              value: req['id'] as int,
              child: Text(
                req['requirement_name'],
                style: TextStyle(color: primaryTextColor),
              ),
            );
          }).toList(),
      onChanged:
          _isSubmitting || _majorRequirements.isEmpty
              ? null
              : (value) => setState(() => _selectedRequirementId = value),
      validator:
          (value) => value == null ? 'add_subject_error_select_req'.tr : null,
      dropdownColor: darkerColor,
    );
  }

  Widget _buildHoursDropdown() {
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    return DropdownButtonFormField<int>(
      value: _hours,
      decoration: _inputDecoration('add_subject_hours_label'.tr),
      items:
          List.generate(6, (i) => i + 1).map((h) {
            return DropdownMenuItem<int>(
              value: h,
              child: Text(
                'add_subject_hours_unit'.trParams({'count': '$h'}),
                style: TextStyle(color: primaryTextColor),
              ),
            );
          }).toList(),
      onChanged: _isSubmitting ? null : (v) => setState(() => _hours = v!),
      validator: (v) => v == null ? 'error_field_required'.tr : null,
      dropdownColor: darkerColor,
    );
  }

  Widget _buildLevelDropdown() {
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    return DropdownButtonFormField<int>(
      value: _level,
      decoration: _inputDecoration('add_subject_level_label'.tr),
      items:
          List.generate(5, (i) => i + 1).map((l) {
            return DropdownMenuItem<int>(
              value: l,
              child: Text(
                'add_subject_level_unit'.trParams({'level': '$l'}),
                style: TextStyle(color: primaryTextColor),
              ),
            );
          }).toList(),
      onChanged: _isSubmitting ? null : (v) => setState(() => _level = v!),
      validator: (v) => v == null ? 'error_field_required'.tr : null,
      dropdownColor: darkerColor,
    );
  }

  Widget _buildIsOpenSwitch() {
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;
    return SwitchListTile(
      title: Text(
        'add_subject_is_open_label'.tr,
        style: TextStyle(color: primaryTextColor),
      ),
      value: _isOpen,
      onChanged: _isSubmitting ? null : (v) => setState(() => _isOpen = v),
      activeColor: AppColors.primary,
      inactiveThumbColor: secondaryTextColor,
      contentPadding: EdgeInsets.zero,
      tileColor: lighterColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildSubmitButton() {
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isSubmitting
                ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: primaryTextColor,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  'add_subject_continue_button'.tr,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
      ),
    );
  }

  Widget _buildLoadingIndicator(String text) {
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(color: secondaryTextColor)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    Color? lighterColor = Theme.of(context).cardColor;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: secondaryTextColor),
      filled: true,
      fillColor: lighterColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryDark),
      ),
    );
  }

  Widget _buildErrorMessageWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: AppColors.error.withOpacity(0.2),
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
