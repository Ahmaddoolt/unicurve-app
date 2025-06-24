import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_text_field.dart';
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
    Color? lighterColor = Theme.of(context).scaffoldBackgroundColor;
    return Obx(
      () => Scaffold(
        backgroundColor: lighterColor,
        appBar:
            controller.isCheckingCredentials.value
                ? null
                : CustomAppBar(
                  title: 'login_title'.tr,
                  centerTitle: true,
                  backgroundColor: lighterColor,
                  leading: const Icon(
                    Icons.abc_outlined,
                    color: Colors.transparent,
                  ),
                ),
        body:
            controller.isCheckingCredentials.value
                ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
                : Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Form(
                      key: controller.formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Image.asset(
                            'assets/logo_no_background.png',
                            width: 250,
                            height: 250,
                          ),
                          CustomTextField(
                            controller: controller.emailController,
                            label: 'email_label'.tr,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmail,
                          ),
                          const SizedBox(height: 30),
                          Obx(
                            () => CustomTextField(
                              controller: controller.passwordController,
                              label: 'password_label'.tr,
                              obscureText: controller.isPasswordObscured.value,
                              validator: Validators.validatePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.isPasswordObscured.value
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: controller.togglePasswordVisibility,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Obx(
                            () => RememberMeCheckbox(
                              value: controller.rememberMe.value,
                              onChanged:
                                  (value) =>
                                      controller.rememberMe.value =
                                          value ?? false,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Obx(
                            () =>
                                controller.isLoading.value
                                    ? const CircularProgressIndicator(
                                      color: AppColors.primary,
                                    )
                                    : CustomButton(
                                      onPressed: controller.login,
                                      text: 'login_button'.tr,
                                    ),
                          ),
                          const SizedBox(height: 10),
                          Column(
                            children: [
                              TextButton(
                                onPressed:
                                    () => Get.to(
                                      () => const SignupView(),
                                      binding: SignupBinding(),
                                    ),
                                child: Text(
                                  'signup_prompt'.tr,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    () => Get.to(
                                      () => const AdminRegistrationView(),
                                      binding: AdminRegistrationBinding(),
                                    ),
                                child: Text(
                                  'admin_reg_prompt'.tr,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
