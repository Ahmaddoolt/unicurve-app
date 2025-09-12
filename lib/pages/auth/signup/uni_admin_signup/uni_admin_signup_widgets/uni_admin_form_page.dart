import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_text_field.dart';
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

    return Obx(() {
      final isArabic = Get.locale?.languageCode == 'ar';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: controller.adminFormKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomTextField(
                  controller: controller.firstNameController,
                  label: 'first_name_label'.tr,
                  validator: Validators.validateName,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: controller.lastNameController,
                  label: 'last_name_label'.tr,
                  validator: Validators.validateName,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: controller.phoneNumberController,
                  label: 'phone_number_label'.tr,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhoneNumber,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: controller.emailController,
                  label: 'email_label'.tr,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: controller.passwordController,
                  label: 'password_label'.tr,
                  obscureText: controller.isPasswordObscured.value,
                  validator: Validators.validatePassword,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordObscured.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: controller.confirmPasswordController,
                  label: 'confirm_password_label'.tr,
                  obscureText: controller.isConfirmPasswordObscured.value,
                  validator:
                      (value) =>
                          value != controller.passwordController.text
                              ? 'error_passwords_no_match'.tr
                              : null,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isConfirmPasswordObscured.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: controller.toggleConfirmPasswordVisibility,
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: controller.positionController,
                  label: 'position_label'.tr,
                  validator: Validators.validateRequired,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  onPressed: controller.goToNextPage,
                  text: 'next_button'.tr,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
