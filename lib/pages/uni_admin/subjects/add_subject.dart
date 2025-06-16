import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/subject.dart';
import 'package:unicurve/pages/uni_admin/subjects/add_subjects_relations.dart';

class AddSubjectBasicPage extends StatefulWidget {
  const AddSubjectBasicPage({super.key});

  @override
  AddSubjectBasicPageState createState() => AddSubjectBasicPageState();
}

class AddSubjectBasicPageState extends State<AddSubjectBasicPage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  // Controllers
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // State variables
  int _hours = 1;
  bool _isOpen = false;
  int? _majorId;
  int _level = 1;
  int? _selectedRequirementId; // CHANGE: This will hold the ID, not the name string.

  // Data lists
  List<Map<String, dynamic>> _majors = [];
  List<Map<String, dynamic>> _majorRequirements = [];

  // Loading states
  bool _isLoadingMajors = true;
  bool _isLoadingRequirements = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMajors();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchMajors() async {
    setState(() { _isLoadingMajors = true; _errorMessage = null; });
    try {
      final response = await supabase.from('majors').select('id, name');
      if (mounted) {
        setState(() {
          _majors = List<Map<String, dynamic>>.from(response);
          _isLoadingMajors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Error fetching majors: $e');
        setState(() => _isLoadingMajors = false);
      }
    }
  }

  Future<void> _fetchRequirementsForMajor(int majorId) async {
    setState(() {
      _isLoadingRequirements = true;
      _majorRequirements = [];
      _selectedRequirementId = null; // Reset selection
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
        _showError('Error fetching requirements: $e');
        setState(() => _isLoadingRequirements = false);
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Please fill in all required fields');
      return;
    }
    _formKey.currentState!.save();

    setState(() { _isSubmitting = true; _errorMessage = null; });

    try {
      final subject = Subject(
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        hours: _hours,
        isOpen: _isOpen,
        majorId: _majorId,
        level: _level,
        // CHANGE: Convert the selected integer ID to a string to be stored in the 'type' text column.
        type: _selectedRequirementId,
      );

      final response = await supabase
          .from('subjects')
          .insert(subject.toMap())
          .select()
          .single();

      if (mounted) {
        final newSubject = Subject.fromMap(response);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AddSubjectRelationsPage(subject: newSubject),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Error adding subject: ${e.toString()}');
        setState(() { _isSubmitting = false; });
      }
    }
  }
  
  void _showError(String message) {
    setState(() { _errorMessage = message; });
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: const CustomAppBar(
        title: 'Add Subject - Step 1/2',
        centerTitle: true,
        backgroundColor: AppColors.darkBackground,
      ),
      body: _isLoadingMajors
          ? _buildLoadingIndicator('Loading Majors...')
          : SingleChildScrollView(
              padding: EdgeInsets.all(scaleConfig.scale(16)),
              child: Card(
                color: AppColors.darkBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(scaleConfig.scale(16)),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(scaleConfig.scale(16)),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Subject Details', scaleConfig),
                        const SizedBox(height: 16),
                        _buildTextField(controller: _codeController, label: 'Subject Code*'),
                        const SizedBox(height: 16),
                        _buildTextField(controller: _nameController, label: 'Subject Name*'),
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
                        _buildTextField(controller: _descriptionController, label: 'Description', maxLines: 3, isRequired: false),
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

  // --- WIDGET BUILDER METHODS ---

  Widget _buildSectionHeader(String title, ScaleConfig scaleConfig) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: scaleConfig.scaleText(18),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, int maxLines = 1, bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.darkTextPrimary),
      decoration: _inputDecoration(label),
      maxLines: maxLines,
      validator: isRequired ? (value) => value!.trim().isEmpty ? 'This field is required' : null : null,
      enabled: !_isSubmitting,
    );
  }

  Widget _buildMajorDropdown() {
    return DropdownButtonFormField<int>(
      value: _majorId,
      decoration: _inputDecoration('Major*'),
      items: _majors.map((major) {
        return DropdownMenuItem<int>(
          value: major['id'] as int,
          child: Text(major['name'], style: const TextStyle(color: AppColors.darkTextPrimary)),
        );
      }).toList(),
      onChanged: _isSubmitting ? null : (value) {
        if (value != null && value != _majorId) {
          setState(() => _majorId = value);
          _fetchRequirementsForMajor(value);
        }
      },
      validator: (value) => value == null ? 'Please select a major' : null,
      dropdownColor: AppColors.darkBackground,
    );
  }

  Widget _buildRequirementTypeDropdown() {
    if (_isLoadingRequirements) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    // CHANGE: The dropdown is now of type <int?> to handle the ID.
    return DropdownButtonFormField<int>(
      value: _selectedRequirementId,
      decoration: _inputDecoration('Requirement Type*'),
      hint: _majorRequirements.isEmpty ? const Text('No requirements for this major', style: TextStyle(color: AppColors.darkTextSecondary)) : null,
      items: _majorRequirements.map((req) {
        // CHANGE: The value is the integer ID, the child is the Text widget with the name.
        return DropdownMenuItem<int>(
          value: req['id'] as int,
          child: Text(req['requirement_name'], style: const TextStyle(color: AppColors.darkTextPrimary)),
        );
      }).toList(),
      onChanged: _isSubmitting || _majorRequirements.isEmpty 
          ? null 
          : (value) => setState(() => _selectedRequirementId = value),
      validator: (value) => value == null ? 'Please select a requirement type' : null,
      dropdownColor: AppColors.darkBackground,
    );
  }

  Widget _buildHoursDropdown() {
    return DropdownButtonFormField<int>(
      value: _hours,
      decoration: _inputDecoration('Hours*'),
      items: List.generate(6, (i) => i + 1).map((h) {
        return DropdownMenuItem<int>(value: h, child: Text('$h hr', style: const TextStyle(color: AppColors.darkTextPrimary)));
      }).toList(),
      onChanged: _isSubmitting ? null : (v) => setState(() => _hours = v!),
      validator: (v) => v == null ? 'Required' : null,
      dropdownColor: AppColors.darkBackground,
    );
  }

  Widget _buildLevelDropdown() {
    return DropdownButtonFormField<int>(
      value: _level,
      decoration: _inputDecoration('Level*'),
      items: List.generate(5, (i) => i + 1).map((l) {
        return DropdownMenuItem<int>(value: l, child: Text('Level $l', style: const TextStyle(color: AppColors.darkTextPrimary)));
      }).toList(),
      onChanged: _isSubmitting ? null : (v) => setState(() => _level = v!),
      validator: (v) => v == null ? 'Required' : null,
      dropdownColor: AppColors.darkBackground,
    );
  }

  Widget _buildIsOpenSwitch() {
    return SwitchListTile(
      title: const Text('Is Open for Registration', style: TextStyle(color: AppColors.darkTextPrimary)),
      value: _isOpen,
      onChanged: _isSubmitting ? null : (v) => setState(() => _isOpen = v),
      activeColor: AppColors.primary,
      inactiveThumbColor: AppColors.darkTextSecondary,
      contentPadding: EdgeInsets.zero,
      tileColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSubmitting
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text(
                'Continue to Relationships',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              ),
      ),
    );
  }

  Widget _buildLoadingIndicator(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(color: AppColors.darkTextSecondary)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryDark)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryDark)),
    );
  }

  Widget _buildErrorMessageWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.error)),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error))),
          ],
        ),
      ),
    );
  }
}