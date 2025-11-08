// lib/pages/auth/signup/uni_admin_signup/uni_admin_signup_widgets/university_form_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/validators.dart';
import 'package:unicurve/pages/auth/signup/uni_admin_signup/uni_admin_registration_controller.dart';

class UniversityFormPage extends StatefulWidget {
  const UniversityFormPage({super.key});

  @override
  State<UniversityFormPage> createState() => _UniversityFormPageState();
}

class _UniversityFormPageState extends State<UniversityFormPage>
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
          key: controller.universityFormKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: controller.universityNameController,
                  decoration:
                      customInputDecoration(labelText: 'uni_name_label'.tr),
                  style: theme.textTheme.bodyLarge,
                  validator: Validators.validateRequired,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.universityShortNameController,
                  decoration: customInputDecoration(
                      labelText: 'uni_short_name_label'.tr),
                  style: theme.textTheme.bodyLarge,
                  validator: Validators.validateRequired,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: controller.selectedUniversityType.value,
                  decoration:
                      customInputDecoration(labelText: 'uni_type_label'.tr),
                  style: theme.textTheme.bodyLarge,
                  dropdownColor:
                      isDarkMode ? const Color(0xFF2D3748) : theme.cardColor,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: theme.textTheme.bodyMedium?.color),
                  items: [
                    {'value': 'Private', 'label': 'private'.tr},
                    {'value': 'Public', 'label': 'public'.tr},
                  ].map((item) {
                    return DropdownMenuItem<String>(
                      value: item['value'],
                      child: Text(item['label']!),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      controller.selectedUniversityType.value = value!,
                  validator: (value) =>
                      value == null ? 'error_uni_type_required'.tr : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Map<String, String>>(
                  value: controller.selectedUniversityLocation.value,
                  decoration:
                      customInputDecoration(labelText: 'uni_location_label'.tr),
                  hint: Text('select_location_hint'.tr),
                  style: theme.textTheme.bodyLarge,
                  dropdownColor:
                      isDarkMode ? const Color(0xFF2D3748) : theme.cardColor,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: theme.textTheme.bodyMedium?.color),
                  items: controller.translatableLocations.map((location) {
                    return DropdownMenuItem<Map<String, String>>(
                      value: location,
                      child: Text(location['key']!.tr),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      controller.selectedUniversityLocation.value = value,
                  validator: (value) =>
                      value == null ? 'error_select_location'.tr : null,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        onPressed: controller.goToPreviousPage,
                        text: 'back_button'.tr,
                        backgroundColor:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: controller.isLoading.value
                          ? Center(
                              child: SizedBox(
                                height: 60,
                                width: 60,
                                child: Lottie.asset(
                                    'assets/animations/5loading.json'),
                              ),
                            )
                          : CustomButton(
                              onPressed: () => controller.submitRequest(),
                              text: 'submit_button'.tr,
                              gradient: AppColors.primaryGradient,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
