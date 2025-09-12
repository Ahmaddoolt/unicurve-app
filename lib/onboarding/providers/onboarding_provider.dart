import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:unicurve/onboarding/data/onboarding_repository.dart';
import 'package:unicurve/pages/auth/login/login_view.dart';
import 'package:unicurve/settings/settings_provider.dart';

final onboardingRepositoryProvider = Provider((ref) => OnboardingRepository());

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, int>((
  ref,
) {
  return OnboardingNotifier(ref);
});

class OnboardingNotifier extends StateNotifier<int> {
  OnboardingNotifier(this._ref) : super(0);
  final Ref _ref;

  final PageController pageController = PageController();

  void selectLanguage(Locale locale) {
    _ref
        .read(languageProvider.notifier)
        .setLanguage(locale.languageCode, locale.countryCode ?? '');

    nextPage();
  }

  void nextPage() {
    if (state < 1) {
      state++;
      pageController.animateToPage(
        state,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> completeOnboarding(BuildContext context) async {
    await _ref.read(onboardingRepositoryProvider).setOnboardingCompleted();

    if (context.mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
    }
  }
}
