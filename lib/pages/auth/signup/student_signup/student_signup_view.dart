// lib/pages/auth/signup/student_signup/student_signup_view.dart

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
import 'package:unicurve/pages/auth/login/login_view.dart';
import 'package:unicurve/pages/auth/signup/student_signup/student_signup_controller.dart';

class SignupView extends GetView<SignupController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isArabic = Get.locale?.languageCode == 'ar';

    final appBar = CustomAppBar(
      title: 'student_signup_title'.tr,
      centerTitle: true,
      useGradient: !isDarkMode,
    );

    final bodyContent = Obx(
      () => Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(scaleConfig.scale(16)),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: scaleConfig.isTablet ? 500 : 400),
                child: GlassCard(
                  padding: EdgeInsets.all(scaleConfig.scale(24)),
                  child: Form(
                    key: controller.formKey,
                    child: GetBuilder<SignupController>(
                      builder: (ctrl) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTextField(
                              context: context,
                              controller: ctrl.firstNameController,
                              label: 'first_name_label'.tr,
                              validator: Validators.validateName,
                              isArabic: isArabic,
                            ),
                            SizedBox(height: scaleConfig.scale(16)),
                            _buildTextField(
                              context: context,
                              controller: ctrl.lastNameController,
                              label: 'last_name_label'.tr,
                              validator: Validators.validateName,
                              isArabic: isArabic,
                            ),
                            SizedBox(height: scaleConfig.scale(16)),
                            _buildTextField(
                              context: context,
                              controller: ctrl.universityNumberController,
                              label: 'uni_number_label'.tr,
                              keyboardType: TextInputType.number,
                              validator: Validators.validateUniversityNumber,
                              isArabic: isArabic,
                            ),
                            SizedBox(height: scaleConfig.scale(16)),
                            _buildLocationDropdown(ctrl, theme),
                            SizedBox(height: scaleConfig.scale(16)),
                            _buildUniversityDropdown(ctrl, theme),
                            SizedBox(height: scaleConfig.scale(16)),
                            _buildMajorDropdown(ctrl, theme),
                            SizedBox(height: scaleConfig.scale(16)),
                            _buildTextField(
                              context: context,
                              controller: ctrl.emailController,
                              label: 'email_label'.tr,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.validateEmail,
                              isArabic: isArabic,
                            ),
                            SizedBox(height: scaleConfig.scale(16)),
                            _buildPasswordFields(
                                context, ctrl, theme, isArabic, scaleConfig),
                            SizedBox(height: scaleConfig.scale(24)),
                            SizedBox(
                              width: double.infinity,
                              child: CustomButton(
                                onPressed: () => ctrl.signUp(),
                                text: 'signup_prompt'.tr.split('?').last.trim(),
                                gradient: AppColors.primaryGradient,
                              ),
                            ),
                            SizedBox(height: scaleConfig.scale(16)),
                            _buildLoginPrompt(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (controller.isLoading.value)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: Center(
                  child: Lottie.asset(
                    'assets/animations/5loading.json',
                    width: 150,
                    height: 150,
                  ),
                ),
              ),
            ),
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

  // --- THIS IS THE KEY FIX: A consistent InputDecoration helper ---
  InputDecoration _customInputDecoration(BuildContext context, String label) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
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

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String? Function(String?)? validator,
    required bool isArabic,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _customInputDecoration(context, label)
          .copyWith(suffixIcon: suffixIcon),
      style: Theme.of(context).textTheme.bodyLarge,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  Widget _buildLocationDropdown(SignupController ctrl, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return DropdownButtonFormField<Map<String, String>>(
      value: ctrl.selectedLocation,
      hint: Text('select_location_hint'.tr),
      isExpanded: true,
      style: theme.textTheme.bodyLarge,
      dropdownColor: isDarkMode ? const Color(0xFF2D3748) : theme.cardColor,
      decoration:
          _customInputDecoration(Get.context!, 'select_location_hint'.tr),
      items: ctrl.translatableLocations
          .map<DropdownMenuItem<Map<String, String>>>((location) {
        return DropdownMenuItem<Map<String, String>>(
          value: location,
          child: Text(location['key']!.tr),
        );
      }).toList(),
      onChanged: ctrl.onLocationChanged,
      validator: (value) => value == null ? 'error_select_location'.tr : null,
    );
  }

  Widget _buildUniversityDropdown(SignupController ctrl, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return Obx(() {
      if (ctrl.isUniversitiesLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
      }
      return DropdownButtonFormField<Map<String, dynamic>>(
        value: ctrl.selectedUniversity,
        hint: Text('select_university_hint'.tr),
        isExpanded: true,
        style: theme.textTheme.bodyLarge,
        dropdownColor: isDarkMode ? const Color(0xFF2D3748) : theme.cardColor,
        decoration:
            _customInputDecoration(Get.context!, 'select_university_hint'.tr),
        items: ctrl.universities
            .map<DropdownMenuItem<Map<String, dynamic>>>((uni) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: uni,
            child: Text(
              '${uni['name']} (${uni['short_name']})',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged:
            ctrl.selectedLocation == null ? null : ctrl.onUniversityChanged,
        validator: (value) =>
            value == null ? 'error_select_university'.tr : null,
      );
    });
  }

  Widget _buildMajorDropdown(SignupController ctrl, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return Obx(() {
      if (ctrl.isMajorsLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
      }
      return DropdownButtonFormField<Map<String, dynamic>>(
        value: ctrl.selectedMajor,
        hint: Text('select_major_hint'.tr),
        isExpanded: true,
        style: theme.textTheme.bodyLarge,
        dropdownColor: isDarkMode ? const Color(0xFF2D3748) : theme.cardColor,
        decoration:
            _customInputDecoration(Get.context!, 'select_major_hint'.tr),
        items: ctrl.majors.map<DropdownMenuItem<Map<String, dynamic>>>((major) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: major,
            child: Text(major['name'], overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: ctrl.selectedUniversity == null
            ? null
            : (value) {
                ctrl.selectedMajor = value;
                ctrl.update(); // Use update() to refresh GetBuilder
              },
        validator: (value) => value == null ? 'error_select_major'.tr : null,
      );
    });
  }

  Widget _buildPasswordFields(BuildContext context, SignupController ctrl,
      ThemeData theme, bool isArabic, ScaleConfig scaleConfig) {
    return Column(
      children: [
        Obx(
          () => _buildTextField(
            context: context,
            controller: ctrl.passwordController,
            label: 'password_label'.tr,
            obscureText: ctrl.obscurePassword.value,
            validator: Validators.validatePassword,
            textInputAction: TextInputAction.next,
            isArabic: isArabic,
            suffixIcon: IconButton(
              icon: Icon(
                ctrl.obscurePassword.value
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: theme.textTheme.bodyMedium?.color,
              ),
              onPressed: () =>
                  ctrl.obscurePassword.value = !ctrl.obscurePassword.value,
            ),
          ),
        ),
        SizedBox(height: scaleConfig.scale(16)),
        Obx(
          () => _buildTextField(
            context: context,
            controller: ctrl.confirmPasswordController,
            label: 'confirm_password_label'.tr,
            obscureText: ctrl.obscureConfirmPassword.value,
            validator: (value) => value != ctrl.passwordController.text
                ? 'error_passwords_no_match'.tr
                : null,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => ctrl.signUp(),
            isArabic: isArabic,
            suffixIcon: IconButton(
              icon: Icon(
                ctrl.obscureConfirmPassword.value
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: theme.textTheme.bodyMedium?.color,
              ),
              onPressed: () => ctrl.obscureConfirmPassword.value =
                  !ctrl.obscureConfirmPassword.value,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: TextButton(
        onPressed: () => Get.off(() => const LoginPage()),
        child: Text(
          'login_prompt'.tr,
          style: const TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
