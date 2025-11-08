// lib/pages/auth/signup/uni_admin_signup/uni_admin_signup_widgets/uni_admin_form_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/validators.dart';
import 'package:unicurve/pages/auth/signup/uni_admin_signup/uni_admin_registration_controller.dart';

class AdminFormPage extends StatefulWidget {
  const AdminFormPage({super.key});

  @override
  State<AdminFormPage> createState() => _AdminFormPageState();
}

class _AdminFormPageState extends State<AdminFormPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = Get.find<AdminRegistrationController>();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // --- THIS IS THE KEY FIX: A consistent InputDecoration helper ---
    InputDecoration customInputDecoration({required String labelText}) {
      return InputDecoration(
        labelText: labelText,
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

    return Obx(() {
      final isArabic = Get.locale?.languageCode == 'ar';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: controller.adminFormKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: controller.firstNameController,
                  decoration:
                      customInputDecoration(labelText: 'first_name_label'.tr),
                  style: theme.textTheme.bodyLarge,
                  validator: Validators.validateName,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.lastNameController,
                  decoration:
                      customInputDecoration(labelText: 'last_name_label'.tr),
                  style: theme.textTheme.bodyLarge,
                  validator: Validators.validateName,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.phoneNumberController,
                  decoration:
                      customInputDecoration(labelText: 'phone_number_label'.tr),
                  style: theme.textTheme.bodyLarge,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhoneNumber,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.emailController,
                  decoration:
                      customInputDecoration(labelText: 'email_label'.tr),
                  style: theme.textTheme.bodyLarge,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.passwordController,
                  decoration:
                      customInputDecoration(labelText: 'password_label'.tr)
                          .copyWith(
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
                  style: theme.textTheme.bodyLarge,
                  obscureText: controller.isPasswordObscured.value,
                  validator: Validators.validatePassword,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.confirmPasswordController,
                  decoration: customInputDecoration(
                          labelText: 'confirm_password_label'.tr)
                      .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isConfirmPasswordObscured.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      onPressed: controller.toggleConfirmPasswordVisibility,
                    ),
                  ),
                  style: theme.textTheme.bodyLarge,
                  obscureText: controller.isConfirmPasswordObscured.value,
                  validator: (value) =>
                      value != controller.passwordController.text
                          ? 'error_passwords_no_match'.tr
                          : null,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.positionController,
                  decoration:
                      customInputDecoration(labelText: 'position_label'.tr),
                  style: theme.textTheme.bodyLarge,
                  validator: Validators.validateRequired,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    onPressed: controller.goToNextPage,
                    text: 'next_button'.tr,
                    gradient: AppColors.primaryGradient,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
