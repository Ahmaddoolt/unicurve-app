import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_text_field.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/core/utils/validators.dart';
import 'package:unicurve/pages/auth/login/login_view.dart';
import 'package:unicurve/pages/auth/signup/student_signup/student_signup_controller.dart';
import 'package:unicurve/pages/auth/signup/student_signup/student_signup_dropdowns.dart';

class SignupView extends GetView<SignupController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final isArabic = Get.locale?.languageCode == 'ar';
    Color? lighterColor = Theme.of(context).scaffoldBackgroundColor;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: lighterColor,
        appBar: CustomAppBar(
          title: 'student_signup_title'.tr,
          centerTitle: true,
          backgroundColor: lighterColor,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(scaleConfig.scale(24)),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: controller.formKey,
                  child: GetBuilder<SignupController>(
                    builder: (ctrl) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: scaleConfig.scale(12)),
                          CustomTextField(
                            controller: ctrl.firstNameController,
                            label: 'first_name_label'.tr,
                            validator: Validators.validateName,
                            textDirection:
                                isArabic
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                          ),
                          SizedBox(height: scaleConfig.scale(16)),
                          CustomTextField(
                            controller: ctrl.lastNameController,
                            label: 'last_name_label'.tr,
                            validator: Validators.validateName,
                            textDirection:
                                isArabic
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                          ),
                          SizedBox(height: scaleConfig.scale(16)),
                          CustomTextField(
                            controller: ctrl.universityNumberController,
                            label: 'uni_number_label'.tr,
                            keyboardType: TextInputType.number,
                            validator: Validators.validateUniversityNumber,
                            textDirection:
                                isArabic
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                          ),
                          SizedBox(height: scaleConfig.scale(16)),

                          DropdownButtonFormField<Map<String, String>>(
                            value: ctrl.selectedLocation,
                            hint: Text('select_location_hint'.tr),
                            isExpanded: true,
                            items:
                                ctrl.translatableLocations.map<
                                  DropdownMenuItem<Map<String, String>>
                                >((location) {
                                  return DropdownMenuItem<Map<String, String>>(
                                    value: location,
                                    child: Text(location['key']!.tr),
                                  );
                                }).toList(),
                            onChanged: ctrl.onLocationChanged,
                            validator:
                                (value) =>
                                    value == null
                                        ? 'error_select_location'.tr
                                        : null,
                          ),

                          SizedBox(height: scaleConfig.scale(16)),
                          Obx(
                            () =>
                                ctrl.isUniversitiesLoading.value
                                    ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                    : UniversityDropdown(
                                      value: ctrl.selectedUniversity,
                                      items: ctrl.universities,
                                      onChanged:
                                          ctrl.selectedLocation == null
                                              ? null
                                              : ctrl.onUniversityChanged,
                                    ),
                          ),
                          SizedBox(height: scaleConfig.scale(16)),
                          Obx(
                            () =>
                                ctrl.isMajorsLoading.value
                                    ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                    : MajorDropdown(
                                      value: ctrl.selectedMajor,
                                      items: ctrl.majors,
                                      onChanged:
                                          ctrl.selectedUniversity == null
                                              ? null
                                              : (value) {
                                                ctrl.selectedMajor = value;
                                              },
                                    ),
                          ),
                          SizedBox(height: scaleConfig.scale(16)),
                          CustomTextField(
                            controller: ctrl.emailController,
                            label: 'email_label'.tr,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmail,
                            textDirection:
                                isArabic
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                          ),
                          SizedBox(height: scaleConfig.scale(16)),
                          Obx(
                            () => CustomTextField(
                              controller: ctrl.passwordController,
                              label: 'password_label'.tr,
                              obscureText: ctrl.obscurePassword.value,
                              validator: Validators.validatePassword,
                              textInputAction: TextInputAction.next,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  ctrl.obscurePassword.value
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                ),
                                onPressed:
                                    () =>
                                        ctrl.obscurePassword.value =
                                            !ctrl.obscurePassword.value,
                              ),
                              textDirection:
                                  isArabic
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                            ),
                          ),
                          SizedBox(height: scaleConfig.scale(16)),
                          Obx(
                            () => CustomTextField(
                              controller: ctrl.confirmPasswordController,
                              label: 'confirm_password_label'.tr,
                              obscureText: ctrl.obscureConfirmPassword.value,
                              validator:
                                  (value) =>
                                      value != ctrl.passwordController.text
                                          ? 'error_passwords_no_match'.tr
                                          : null,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => ctrl.signUp(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  ctrl.obscureConfirmPassword.value
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                ),
                                onPressed:
                                    () =>
                                        ctrl.obscureConfirmPassword.value =
                                            !ctrl.obscureConfirmPassword.value,
                              ),
                              textDirection:
                                  isArabic
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                            ),
                          ),
                          SizedBox(height: scaleConfig.scale(24)),
                          Obx(
                            () =>
                                ctrl.isLoading.value
                                    ? const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                    )
                                    : CustomButton(
                                      onPressed: ctrl.signUp,
                                      text: 'signup_prompt'.tr,
                                    ),
                          ),
                          SizedBox(height: scaleConfig.scale(16)),
                          Center(
                            child: TextButton(
                              onPressed: () => Get.off(() => const LoginPage()),
                              child: Text(
                                'login_prompt'.tr,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: scaleConfig.scaleText(13),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
