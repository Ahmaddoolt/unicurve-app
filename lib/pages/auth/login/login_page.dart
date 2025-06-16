import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/bottom_nativgation/student_bottom_bar/student_bottom_navigation_bar.dart';
import 'package:unicurve/core/utils/bottom_nativgation/uni_admin_bottom_bar/uni_admin_bottom_navigation_bar.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_text_field.dart';
import 'package:unicurve/core/utils/validators.dart';
import 'package:unicurve/data/services/auth_services.dart';
import 'package:unicurve/pages/auth/login/login_widgets/rember_checkbox.dart';
import 'package:unicurve/pages/auth/signup/signup_page.dart';
import 'package:unicurve/pages/uni_admin/uni_admin_registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isCheckingCredentials = true; // New state for "Remember Me" loading

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    setState(() => _isCheckingCredentials = true);
    final credentials = await _authService.getSavedCredentials();
    if (credentials != null && credentials['isRememberMe'] == true) {
      final currentUser = _authService.getCurrentUser();
      if (currentUser != null && currentUser.id == credentials['uid']) {
        setState(() {
          _rememberMe = true;
        });
        if (mounted) {
          await _navigateBasedOnUserRole(currentUser.id);
        }
      }
    }
    if (mounted) {
      setState(() => _isCheckingCredentials = false);
    }
  }

  Future<void> _navigateBasedOnUserRole(String userId) async {
    // Check if user ID is the specific admin ID
    if (userId == '4e496a89-7fa7-49b4-911e-6c3bcb1b74e8') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentBottomBar()),
      );
      return;
    }

    // Check if user is in uni_admin table
    final userData = await _authService.getUserRole(userId);
    if (userData != null) {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (_) => UniAdminBottomBar(),
          //universityId: userData['university_id']
        ),
      );
    } else {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (_) => const StudentBottomBar()),
      );
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final user = await _authService.signIn(email: email, password: password);
      if (user != null) {
        if (_rememberMe) {
          await _authService.saveCredentials(isRememberMe: true, uid: user.id);
        } else {
          await _authService.clearCredentials();
        }
        if (mounted) {
          await _navigateBasedOnUserRole(user.id);
        }
      } else {
        throw Exception('Login failed');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          _isCheckingCredentials
              ? null
              : CustomAppBar(
                title: "UniCurve",
                centerTitle: true,
                backgroundColor: AppColors.darkBackground,
                leading: Icon(Icons.abc_outlined, color: Colors.transparent),
              ),
      body:
          _isCheckingCredentials
              ? Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
              : Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Image.asset(
                          'assets/logo_no_background.png',
                          width: 250,
                          height: 250,
                        ),
                        CustomTextField(
                          controller: _emailController,
                          label: "Email",
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                        ),
                        const SizedBox(height: 30),
                        CustomTextField(
                          controller: _passwordController,
                          label: "Password",
                          obscureText: true,
                          validator: Validators.validatePassword,
                        ),
                        const SizedBox(height: 12),
                        RememberMeCheckbox(
                          value: _rememberMe,
                          onChanged:
                              (value) =>
                                  setState(() => _rememberMe = value ?? false),
                        ),
                        const SizedBox(height: 40),
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: AppColors.primary,
                            )
                            : CustomButton(onPressed: _login, text: "Login"),
                        const SizedBox(height: 10),
                        Column(
                          children: [
                            TextButton(
                              onPressed:
                                  () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SignupPage(),
                                    ),
                                  ),
                              child: const Text(
                                "Don't have an account? Sign up",
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => const AdminRegistrationPage(),
                                    ),
                                  ),
                              child: const Text(
                                "Register as University Admin",
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
