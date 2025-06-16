import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_text_field.dart';
import 'package:unicurve/core/utils/validators.dart';
import 'package:unicurve/data/services/auth_services.dart';
import 'package:unicurve/domain/models/uni_admin_request.dart';

class AdminRegistrationPage extends StatefulWidget {
  const AdminRegistrationPage({super.key});

  @override
  State<AdminRegistrationPage> createState() => _AdminRegistrationPageState();
}

class _AdminRegistrationPageState extends State<AdminRegistrationPage> {
  final _pageController = PageController();
  final _adminFormKey = GlobalKey<FormState>();
  final _universityFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _positionController = TextEditingController();
  final _universityNameController = TextEditingController();
  final _universityShortNameController = TextEditingController();
  final _universityTypeController = TextEditingController();
  final _universityLocationController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _positionController.dispose();
    _universityNameController.dispose();
    _universityShortNameController.dispose();
    _universityTypeController.dispose();
    _universityLocationController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    // Validate both forms
    final adminFormValid = _adminFormKey.currentState?.validate() ?? false;
    final universityFormValid = _universityFormKey.currentState?.validate() ?? false;

    // Debug which fields are failing validation
    if (!adminFormValid || !universityFormValid) {
      String errorMessage = 'Please correct the following errors:\n';
      if (!adminFormValid) {
        errorMessage += '- Admin form fields are invalid:\n';
        // Log and check each field with detailed validation messages
        print('First Name: "${_firstNameController.text}" (Raw: ${_firstNameController.text.codeUnits})');
        final firstNameError = Validators.validateName(_firstNameController.text);
        if (firstNameError != null) {
          errorMessage += '  - First Name: $firstNameError\n';
        }
        print('Last Name: "${_lastNameController.text}" (Raw: ${_lastNameController.text.codeUnits})');
        final lastNameError = Validators.validateName(_lastNameController.text);
        if (lastNameError != null) {
          errorMessage += '  - Last Name: $lastNameError\n';
        }
        print('Phone Number: "${_phoneNumberController.text}" (Raw: ${_phoneNumberController.text.codeUnits})');
        final phoneError = Validators.validatePhoneNumber(_firstNameController.text);
        if (phoneError != null) {
          errorMessage += '  - Phone Number: $phoneError\n';
        }
        print('Email: "${_emailController.text}" (Raw: ${_emailController.text.codeUnits})');
        final emailError = Validators.validateEmail(_emailController.text);
        if (emailError != null) {
          errorMessage += '  - Email: $emailError\n';
        }
        print('Password: "${_passwordController.text}" (Raw: ${_passwordController.text.codeUnits})');
        final passwordError = Validators.validatePassword(_passwordController.text);
        if (passwordError != null) {
          errorMessage += '  - Password: $passwordError\n';
        }
        print('Position: "${_positionController.text}" (Raw: ${_positionController.text.codeUnits})');
        final positionError = Validators.validateRequired(_positionController.text);
        if (positionError != null) {
          errorMessage += '  - Position: $positionError\n';
        }
      }
      if (!universityFormValid) {
        errorMessage += '- University form fields are invalid:\n';
        print('University Name: "${_universityNameController.text}" (Raw: ${_universityNameController.text.codeUnits})');
        final uniNameError = Validators.validateRequired(_universityNameController.text);
        if (uniNameError != null) {
          errorMessage += '  - University Name: $uniNameError\n';
        }
        print('University Short Name: "${_universityShortNameController.text}" (Raw: ${_universityShortNameController.text.codeUnits})');
        final uniShortNameError = Validators.validateRequired(_universityShortNameController.text);
        if (uniShortNameError != null) {
          errorMessage += '  - University Short Name: $uniShortNameError\n';
        }
        print('University Type: "${_universityTypeController.text}" (Raw: ${_universityTypeController.text.codeUnits})');
        final uniTypeError = Validators.validateRequired(_universityTypeController.text);
        if (uniTypeError != null) {
          errorMessage += '  - University Type: $uniTypeError\n';
        }
        print('University Location: "${_universityLocationController.text}" (Raw: ${_universityLocationController.text.codeUnits})');
        final uniLocationError = Validators.validateRequired(_universityLocationController.text);
        if (uniLocationError != null) {
          errorMessage += '  - University Location: $uniLocationError\n';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
      return;
    }

    // Create a UniAdmin object with trimmed values
    final uniAdmin = UniAdmin(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      position: _positionController.text.trim(),
      universityName: _universityNameController.text.trim(),
      universityShortName: _universityShortNameController.text.trim(),
      universityType: _universityTypeController.text.trim(),
      universityLocation: _universityLocationController.text.trim(),
    );

    setState(() => _isLoading = true);
    try {
      final userId = await _authService.submitAdminRequest(uniAdmin: uniAdmin);
      if (userId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration request submitted. Awaiting approval.'),
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception('User creation failed');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auth Error: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Admin Registration',
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Page 1: Admin Attributes
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _adminFormKey,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomTextField(
                            controller: _firstNameController,
                            label: 'First Name',
                            validator: Validators.validateName,
                            onChanged: (_) => _adminFormKey.currentState?.validate(),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _lastNameController,
                            label: 'Last Name',
                            validator: Validators.validateName,
                            onChanged: (_) => _adminFormKey.currentState?.validate(),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _phoneNumberController,
                            label: 'Phone Number',
                            keyboardType: TextInputType.phone,
                            validator: Validators.validatePhoneNumber,
                            onChanged: (_) => _adminFormKey.currentState?.validate(),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmail,
                            onChanged: (_) => _adminFormKey.currentState?.validate(),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            obscureText: true,
                            validator: Validators.validatePassword,
                            onChanged: (_) => _adminFormKey.currentState?.validate(),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _positionController,
                            label: 'Position in University',
                            validator: Validators.validateRequired,
                            onChanged: (_) => _adminFormKey.currentState?.validate(),
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            onPressed: () {
                              // Log all field values for debugging
                              print('Validating admin form...');
                              print('First Name: "${_firstNameController.text}" (Raw: ${_firstNameController.text.codeUnits})');
                              print('Last Name: "${_lastNameController.text}" (Raw: ${_lastNameController.text.codeUnits})');
                              print('Phone Number: "${_phoneNumberController.text}" (Raw: ${_phoneNumberController.text.codeUnits})');
                              print('Email: "${_emailController.text}" (Raw: ${_emailController.text.codeUnits})');
                              print('Password: "${_passwordController.text}" (Raw: ${_passwordController.text.codeUnits})');
                              print('Position: "${_positionController.text}" (Raw: ${_positionController.text.codeUnits})');

                              if (_adminFormKey.currentState?.validate() ?? false) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                String errorMessage = 'Please correct errors in the admin form:\n';
                                final firstNameError = Validators.validateName(_firstNameController.text);
                                if (firstNameError != null) {
                                  errorMessage += '  - First Name: $firstNameError\n';
                                }
                                final lastNameError = Validators.validateName(_lastNameController.text);
                                if (lastNameError != null) {
                                  errorMessage += '  - Last Name: $lastNameError\n';
                                }
                                final phoneError = Validators.validatePhoneNumber(_phoneNumberController.text);
                                if (phoneError != null) {
                                  errorMessage += '  - Phone Number: $phoneError\n';
                                }
                                final emailError = Validators.validateEmail(_emailController.text);
                                if (emailError != null) {
                                  errorMessage += '  - Email: $emailError\n';
                                }
                                final passwordError = Validators.validatePassword(_passwordController.text);
                                if (passwordError != null) {
                                  errorMessage += '  - Password: $passwordError\n';
                                }
                                final positionError = Validators.validateRequired(_positionController.text);
                                if (positionError != null) {
                                  errorMessage += '  - Position: $positionError\n';
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(errorMessage)),
                                );
                              }
                            },
                            text: 'Next',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Page 2: University Attributes
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _universityFormKey,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomTextField(
                            controller: _universityNameController,
                            label: 'University Name',
                            validator: Validators.validateRequired,
                            onChanged: (_) => _universityFormKey.currentState?.validate(),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _universityShortNameController,
                            label: 'University Short Name',
                            validator: Validators.validateRequired,
                            onChanged: (_) => _universityFormKey.currentState?.validate(),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _universityTypeController,
                            label: 'University Type',
                            validator: Validators.validateRequired,
                            onChanged: (_) => _universityFormKey.currentState?.validate(),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _universityLocationController,
                            label: 'University Location',
                            validator: Validators.validateRequired,
                            onChanged: (_) => _universityFormKey.currentState?.validate(),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  onPressed: () {
                                    _pageController.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  text: 'Back',
                                  backgroundColor: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _isLoading
                                    ? const Center(child: CircularProgressIndicator())
                                    : CustomButton(
                                        onPressed: _submitRequest,
                                        text: 'Submit Request',
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Dot Indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _pageController.hasClients && (_pageController.page ?? 0) == 0
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _pageController.hasClients && (_pageController.page ?? 0) == 1
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}