import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/data/services/app_update_service.dart';
import 'package:unicurve/onboarding/data/onboarding_repository.dart';
import 'package:unicurve/onboarding/view/onboarding_page.dart';
import 'package:unicurve/pages/auth/login/login_view.dart';
import 'package:url_launcher/url_launcher.dart';

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final updateService = AppUpdateService();
    final updateResult = await updateService.anageUpdateCheck();

    if (mounted) {
      if (updateResult.isForced) {
        _showForceUpdateDialog(updateResult.storeUrl);
      } else {
        _navigateToNextScreen();
      }
    }
  }

  Future<void> _navigateToNextScreen() async {
    final onboardingRepository = OnboardingRepository();
    final isOnboardingCompleted =
        await onboardingRepository.isOnboardingCompleted();

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      Get.offAll(() => const LoginPage());
    } else if (isOnboardingCompleted) {
      Get.offAll(() => const LoginPage());
    } else {
      Get.offAll(() => const OnboardingPage());
    }
  }

  void _showForceUpdateDialog(String storeUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text('update_required_title'.tr),
            content: Text('update_required_message'.tr),
            actions: <Widget>[
              TextButton(
                child: Text('update_now_button'.tr),
                onPressed: () async {
                  if (storeUrl.isEmpty) return;
                  final uri = Uri.parse(storeUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo_no_background.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
