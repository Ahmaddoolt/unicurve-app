import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/bottom_nativgation/student_bottom_bar/student_bottom_navigation_bar.dart';
import 'package:unicurve/core/utils/bottom_nativgation/super_admin_bottom_bar/super_admin_bottom_navigation_bar.dart';
import 'package:unicurve/core/utils/bottom_nativgation/uni_admin_bottom_bar/uni_admin_bottom_navigation_bar.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/core/utils/scale_config.dart'; // --- FIX: Import ScaleConfig ---
import 'package:unicurve/data/services/app_update_service.dart';
import 'package:unicurve/data/services/auth_services.dart';
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
    Future.delayed(const Duration(milliseconds: 2500), _initializeApp);
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;

    final updateService = AppUpdateService();
    final updateResult = await updateService.anageUpdateCheck();

    if (mounted) {
      if (updateResult.isForced) {
        _showForceUpdateDialog(updateResult.storeUrl);
      } else {
        await _navigateToNextScreen();
      }
    }
  }

  Future<void> _navigateToNextScreen() async {
    final authService = AuthService();
    final onboardingRepository = OnboardingRepository();

    final credentials = await authService.getSavedCredentials();
    final currentUser = authService.getCurrentUser();

    if (credentials != null &&
        credentials['isRememberMe'] == true &&
        currentUser != null &&
        currentUser.id == credentials['uid']) {
      await _navigateBasedOnUserRole(currentUser.id, authService);
      return;
    }

    final isOnboardingCompleted =
        await onboardingRepository.isOnboardingCompleted();
    if (!isOnboardingCompleted) {
      Get.offAll(() => const OnboardingPage());
      return;
    }

    Get.offAll(() => const LoginPage());
  }

  Future<void> _navigateBasedOnUserRole(
      String userId, AuthService authService) async {
    if (userId == '48157f0b-a061-45d4-a83e-d725dffa0e99') {
      Get.offAll(() => const SuperAdminBottomBar());
      return;
    }

    final userData = await authService.getUserRole(userId);
    if (userData != null) {
      Get.offAll(() => const UniAdminBottomBar());
    } else {
      Get.offAll(() => const StudentBottomBar());
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final scaleConfig = context.scaleConfig; 

    final bodyContent = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/no_back_1025.png', 
            width: scaleConfig.widthPercentage(0.55),
            height: scaleConfig.widthPercentage(0.55),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: scaleConfig.widthPercentage(0.5),
            height: scaleConfig.widthPercentage(0.5),
            child: Lottie.asset('assets/5loading.json'), 
          ),
        ],
      ),
    );

    if (isDarkMode) {
      return GradientScaffold(body: bodyContent);
    } else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: bodyContent,
      );
    }
  }
}
