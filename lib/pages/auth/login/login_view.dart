// lib/pages/auth/login/login_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/core/utils/validators.dart';
import 'package:unicurve/pages/auth/login/login_controller.dart';
import 'package:unicurve/pages/auth/login/login_widgets/rember_checkbox.dart';
import 'package:unicurve/pages/auth/signup/student_signup/student_signup_binding.dart';
import 'package:unicurve/pages/auth/signup/student_signup/student_signup_view.dart';
import 'package:unicurve/pages/auth/signup/uni_admin_signup/admin_registration_binding.dart';
import 'package:unicurve/pages/auth/signup/uni_admin_signup/uni_admin_registration_view.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    final theme = Theme.of(context);
    final scaleConfig = context.scaleConfig;
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBar = CustomAppBar(
      useGradient: !isDarkMode,
      title: 'login_title'.tr,
      centerTitle: true,
      gradient: isDarkMode
          ? AppColors.darkPrimaryGradient
          : AppColors.primaryGradient,
    );

    final bodyContent = SingleChildScrollView(
      padding: EdgeInsets.all(scaleConfig.scale(24)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: scaleConfig.widthPercentage(0.5),
            height: scaleConfig.widthPercentage(0.5),
            child: Lottie.asset(
                'assets/login.json'), // Assuming this is the correct path
          ),
          SizedBox(height: scaleConfig.scale(30)),
          GlassCard(
            padding: EdgeInsets.all(scaleConfig.scale(24)),
            child: Form(
              key: controller.formKey,
              child: Column(
                children: [
                  _buildTextField(
                    context: context,
                    controller: controller.emailController,
                    label: 'email_label'.tr,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  SizedBox(height: scaleConfig.scale(20)),
                  Obx(
                    () => _buildTextField(
                      context: context,
                      controller: controller.passwordController,
                      label: 'password_label'.tr,
                      obscureText: controller.isPasswordObscured.value,
                      validator: Validators.validatePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordObscured.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                    ),
                  ),
                  SizedBox(height: scaleConfig.scale(16)),
                  Obx(
                    () => RememberMeCheckbox(
                      value: controller.rememberMe.value,
                      onChanged: (value) =>
                          controller.rememberMe.value = value ?? false,
                    ),
                  ),
                  SizedBox(height: scaleConfig.scale(24)),
                  Obx(
                    () => controller.isLoading.value
                        ? SizedBox(
                            height: 80,
                            width: 80,
                            child: Lottie.asset(
                              'assets/5loading.json',
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              onPressed: () => controller.login(),
                              text: 'login_button'.tr,
                              gradient: AppColors.primaryGradient,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: scaleConfig.scale(20)),
          _buildSignupPrompts(isDarkMode), // --- FIX: Pass isDarkMode ---
        ],
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

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    InputDecoration loginInputDecoration() {
      if (isDarkMode) {
        return InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.labelLarge,
          filled: true,
          fillColor: Colors.black.withOpacity(0.3),
          suffixIcon: suffixIcon,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 2),
          ),
        );
      } else {
        return InputDecoration(
          labelText: label,
          suffixIcon: suffixIcon,
        ).applyDefaults(theme.inputDecorationTheme);
      }
    }

    return TextFormField(
      controller: controller,
      decoration: loginInputDecoration(),
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscureText,
      style: theme.textTheme.bodyLarge,
    );
  }

  // --- FIX: Method now accepts isDarkMode ---
  Widget _buildSignupPrompts(bool isDarkMode) {
    return Column(
      children: [
        TextButton(
          onPressed: () => Get.to(
            () => const SignupView(),
            binding: SignupBinding(),
          ),
          child: Text(
            'signup_prompt'.tr,
            style: TextStyle(
              // --- FIX: Conditional color ---
              color: isDarkMode ? Colors.white : AppColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Get.to(
            () => const AdminRegistrationView(),
            binding: AdminRegistrationBinding(),
          ),
          child: Text(
            'admin_reg_prompt'.tr,
            style: TextStyle(
              // --- FIX: Conditional color ---
              color: isDarkMode ? Colors.white : AppColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
