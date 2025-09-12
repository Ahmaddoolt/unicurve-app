import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
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
                child:
                    currentPage == 1
                        ? _buildGetStartedButton(context, notifier)
                        : StepIndicator(currentPage: currentPage),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGetStartedButton(
    BuildContext context,
    OnboardingNotifier notifier,
  ) {
    final scaleConfig = context.scaleConfig;
    return ElevatedButton(
      onPressed: () => notifier.completeOnboarding(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF24C28F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(scaleConfig.scale(16)),
        ),
        padding: EdgeInsets.symmetric(
          vertical: scaleConfig.scale(18),
          horizontal: scaleConfig.scale(32),
        ),
        elevation: 5,
      ),
      child: Text(
        'onboarding_get_started_button'.tr,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: scaleConfig.scaleText(16),
        ),
      ),
    );
  }
}
