import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/pages/auth/signup/uni_admin_signup/uni_admin_registration_controller.dart';
import 'package:unicurve/pages/auth/signup/uni_admin_signup/uni_admin_signup_widgets/uni_admin_form_page.dart';
import 'package:unicurve/pages/auth/signup/uni_admin_signup/uni_admin_signup_widgets/university_form_page.dart'
    show UniversityFormPage;
import 'package:unicurve/settings/settings_provider.dart';

class AdminRegistrationView extends ConsumerWidget {
  const AdminRegistrationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(languageProvider);

    final controller = Get.find<AdminRegistrationController>();

    return PopScope(
      canPop: false,
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) {
        if (didPop) return;
        controller.handleBackPress();
      },
      child: Obx(() {
        return Directionality(
          textDirection:
              Get.locale?.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
          child: Scaffold(
            appBar: CustomAppBar(
              title: 'admin_reg_title'.tr,
              centerTitle: true,
            ),
            body: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: controller.pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [AdminFormPage(), UniversityFormPage()],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      2,
                      (index) => _buildDot(
                        context,
                        index,
                        controller.currentPageIndex.value,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDot(BuildContext context, int index, int currentIndex) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            currentIndex == index
                ? Theme.of(context).primaryColor
                : Theme.of(context).textTheme.bodyMedium?.color,
      ),
    );
  }
}
