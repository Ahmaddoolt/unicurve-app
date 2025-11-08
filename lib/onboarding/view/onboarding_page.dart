// lib/onboarding/view/onboarding_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart'; // --- FIX: Import GradientScaffold ---
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/onboarding/providers/onboarding_provider.dart';
import 'package:unicurve/onboarding/widgets/app_info_step.dart';
import 'package:unicurve/onboarding/widgets/language_selection_step.dart';
import 'package:unicurve/onboarding/widgets/step_indicator.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingProvider.notifier);
    final currentPage = ref.watch(onboardingProvider);
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final bodyContent = SafeArea(
      child: Stack(
        children: [
          PageView(
            controller: notifier.pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [LanguageSelectionStep(), AppInfoStep()],
          ),
          Positioned(
            bottom: scaleConfig.scale(40),
            left: scaleConfig.scale(24),
            right: scaleConfig.scale(24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: currentPage == 1
                  ? _buildGetStartedButton(context, notifier)
                  : StepIndicator(currentPage: currentPage),
            ),
          ),
        ],
      ),
    );

    // --- THE KEY FIX IS HERE ---
    // Use GradientScaffold for dark mode and a standard Scaffold for light mode
    if (isDarkMode) {
      return GradientScaffold(body: bodyContent);
    } else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: bodyContent,
      );
    }
  }

  Widget _buildGetStartedButton(
    BuildContext context,
    OnboardingNotifier notifier,
  ) {
    return CustomButton(
      onPressed: () => notifier.completeOnboarding(context),
      text: 'onboarding_get_started_button'.tr,
      gradient: AppColors.primaryGradient,
      textColor: Colors.white,
    );
  }
}
