// lib/pages/auth/signup/uni_admin_signup/uni_admin_registration_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/auth/signup/uni_admin_signup/uni_admin_registration_controller.dart';
import 'package:unicurve/pages/auth/signup/uni_admin_signup/uni_admin_signup_widgets/uni_admin_form_page.dart';
import 'package:unicurve/pages/auth/signup/uni_admin_signup/uni_admin_signup_widgets/university_form_page.dart';
import 'package:unicurve/settings/settings_provider.dart';

class AdminRegistrationView extends ConsumerWidget {
  const AdminRegistrationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(languageProvider);
    final controller = Get.find<AdminRegistrationController>();
    final theme = Theme.of(context);
    final scaleConfig = context.scaleConfig;
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBar = CustomAppBar(
      title: 'admin_reg_title'.tr,
      centerTitle: true,
      useGradient: !isDarkMode,
    );

    final bodyContent = PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        controller.handleBackPress();
      },
      child: Obx(
        () => Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(scaleConfig.scale(16)),
                child: GlassCard(
                  child: PageView(
                    controller: controller.pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [AdminFormPage(), UniversityFormPage()],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
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

  Widget _buildDot(BuildContext context, int index, int currentIndex) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    bool isActive = currentIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: EdgeInsets.symmetric(horizontal: scaleConfig.scale(4)),
      height: scaleConfig.scale(8),
      width: isActive ? scaleConfig.scale(24) : scaleConfig.scale(8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : theme.dividerColor,
        borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
      ),
    );
  }
}
