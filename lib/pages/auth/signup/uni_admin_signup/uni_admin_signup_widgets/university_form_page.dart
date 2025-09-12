import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_text_field.dart';
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

    return Obx(() {
      final isArabic = Get.locale?.languageCode == 'ar';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: controller.universityFormKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomTextField(
                  controller: controller.universityNameController,
                  label: 'uni_name_label'.tr,
                  validator: Validators.validateRequired,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: controller.universityShortNameController,
                  label: 'uni_short_name_label'.tr,
                  validator: Validators.validateRequired,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: controller.selectedUniversityType.value,
                  decoration: InputDecoration(
                    labelText: 'uni_type_label'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  items:
                      [
                        {'value': 'Private', 'label': 'private'.tr},
                        {'value': 'Public', 'label': 'public'.tr},
                      ].map((item) {
                        return DropdownMenuItem<String>(
                          value: item['value'],
                          child: Text(item['label']!),
                        );
                      }).toList(),
                  onChanged:
                      (value) =>
                          controller.selectedUniversityType.value = value!,
                  validator:
                      (value) =>
                          value == null ? 'error_uni_type_required'.tr : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<Map<String, String>>(
                  value: controller.selectedUniversityLocation.value,
                  decoration: InputDecoration(
                    labelText: 'uni_location_label'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  hint: Text('select_location_hint'.tr),
                  items:
                      controller.translatableLocations.map((location) {
                        return DropdownMenuItem<Map<String, String>>(
                          value: location,
                          child: Text(location['key']!.tr),
                        );
                      }).toList(),
                  onChanged:
                      (value) =>
                          controller.selectedUniversityLocation.value = value,
                  validator:
                      (value) =>
                          value == null ? 'error_select_location'.tr : null,
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        onPressed: controller.goToPreviousPage,
                        text: 'back_button'.tr,
                        backgroundColor:
                            Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child:
                          controller.isLoading.value
                              ? const Center(child: CircularProgressIndicator())
                              : CustomButton(
                                onPressed: controller.submitRequest,
                                text: 'submit_button'.tr,
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
