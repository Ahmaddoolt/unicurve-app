import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/bottom_nativgation/student_bottom_bar/student_bottom_navigation_bar.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_text_field.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/core/utils/validators.dart';
import 'package:unicurve/data/services/auth_services.dart';
import 'package:unicurve/domain/models/student.dart';
import 'package:unicurve/pages/auth/login/login_page.dart';
import 'package:unicurve/pages/auth/signup/signup_widgets.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _universityNumberController = TextEditingController();
  List<dynamic> _universities = [];
  List<dynamic> _majors = [];
  Map<String, dynamic>? _selectedUniversity;
  Map<String, dynamic>? _selectedMajor;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  Future<void> _loadUniversities() async {
    try {
      final response = await _authService.getUniversities();
      if (mounted) {
        setState(() => _universities = response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading universities: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadMajors(int universityId) async {
    try {
      final response = await _authService.getMajors(universityId);
      if (mounted) {
        setState(() {
          _majors = response;
          _selectedMajor = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading majors: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<bool> _checkUniqueUniversityNumber(
    String uniNumber,
    int universityId,
  ) async {
    try {
      final response =
          await Supabase.instance.client
              .from('students')
              .select('id')
              .eq('uni_number', uniNumber)
              .eq('university_id', universityId)
              .maybeSingle();
      return response == null; // True if no duplicate exists
    } catch (e) {
      print('Error checking university number: $e');
      return false;
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedUniversity == null || _selectedMajor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a university and major'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final uniNumber = _universityNumberController.text.trim();
    final universityId = _selectedUniversity!['id'] as int;

    // Check for unique university number
    final isUnique = await _checkUniqueUniversityNumber(
      uniNumber,
      universityId,
    );
    if (!isUnique) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('University number already exists for this university'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final student = Student(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      uniNumber: uniNumber,
      universityId: universityId,
      majorId: _selectedMajor!['id'] as int,
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = true);
    try {
      final userId = await _authService.signUp(student: student);
      if (userId != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentBottomBar()),
        );
      } else {
        throw Exception('User creation failed');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _universityNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = ScaleConfig(context);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: const CustomAppBar(
        title: 'Sign Up',
        centerTitle: true,
        backgroundColor: AppColors.darkBackground,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(scaleConfig.scale(24)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: scaleConfig.scale(12)),
                  CustomTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    validator: Validators.validateName,
                  ),
                  SizedBox(height: scaleConfig.scale(16)),
                  CustomTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    validator: Validators.validateName,
                  ),
                  SizedBox(height: scaleConfig.scale(16)),
                  CustomTextField(
                    controller: _universityNumberController,
                    label: 'University Number',
                    keyboardType: TextInputType.number,
                    validator: Validators.validateUniversityNumber,
                  ),
                  SizedBox(height: scaleConfig.scale(16)),
                  UniversityDropdown(
                    value: _selectedUniversity,
                    items: _universities,
                    onChanged: (value) {
                      final selected = value as Map<String, dynamic>;
                      setState(() => _selectedUniversity = selected);
                      _loadMajors(selected['id']);
                    },
                  ),
                  SizedBox(height: scaleConfig.scale(16)),
                  MajorDropdown(
                    value: _selectedMajor,
                    items: _majors,
                    onChanged:
                        (value) => setState(
                          () => _selectedMajor = value as Map<String, dynamic>,
                        ),
                  ),
                  SizedBox(height: scaleConfig.scale(16)),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  SizedBox(height: scaleConfig.scale(16)),
                  StatefulBuilder(
                    builder:
                        (context, setState) => CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          obscureText: _obscurePassword,
                          validator: Validators.validatePassword,
                          textInputAction: TextInputAction.next,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.darkTextSecondary,
                            ),
                            onPressed:
                                () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                          ),
                        ),
                  ),
                  SizedBox(height: scaleConfig.scale(16)),
                  StatefulBuilder(
                    builder:
                        (context, setState) => CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          obscureText: _obscureConfirmPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _signUp(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.darkTextSecondary,
                            ),
                            onPressed:
                                () => setState(
                                  () =>
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                ),
                          ),
                        ),
                  ),
                  SizedBox(height: scaleConfig.scale(24)),
                  _isLoading
                      ? Center(
                        child: const CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomButton(onPressed: _signUp, text: 'Sign Up'),
                        ],
                      ),
                  SizedBox(height: scaleConfig.scale(16)),
                  Center(
                    child: TextButton(
                      onPressed:
                          () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          ),
                      child: Text(
                        'Already have an account? Log in',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: scaleConfig.scaleText(11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
