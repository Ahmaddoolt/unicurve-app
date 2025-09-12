import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/bottom_nativgation/student_bottom_bar/student_bottom_navigation_bar.dart';
import 'package:unicurve/core/utils/bottom_nativgation/super_admin_bottom_bar/super_admin_bottom_navigation_bar.dart';
import 'package:unicurve/core/utils/bottom_nativgation/uni_admin_bottom_bar/uni_admin_bottom_navigation_bar.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/data/services/auth_services.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  var rememberMe = false.obs;
  var isLoading = false.obs;
  var isCheckingCredentials = true.obs;
  var isPasswordObscured = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedCredentials();
  }

  void togglePasswordVisibility() {
    isPasswordObscured.value = !isPasswordObscured.value;
  }

  Future<void> _loadSavedCredentials() async {
    isCheckingCredentials.value = true;
    final credentials = await _authService.getSavedCredentials();
    if (credentials != null && credentials['isRememberMe'] == true) {
      final currentUser = _authService.getCurrentUser();
      if (currentUser != null && currentUser.id == credentials['uid']) {
        rememberMe.value = true;
        await _navigateBasedOnUserRole(currentUser.id);
      }
    }
    isCheckingCredentials.value = false;
  }

  Future<void> _navigateBasedOnUserRole(String userId) async {
    if (userId == '48157f0b-a061-45d4-a83e-d725dffa0e99') {
      Get.offAll(() => const SuperAdminBottomBar());
      return;
    }

    final userData = await _authService.getUserRole(userId);
    if (userData != null) {
      Get.offAll(() => const UniAdminBottomBar());
    } else {
      Get.offAll(() => const StudentBottomBar());
    }
  }

  Future<void> login() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    final email = emailController.text.trim();
    final password = passwordController.text;

    try {
      final user = await _authService.signIn(email: email, password: password);
      if (user != null) {
        if (rememberMe.value) {
          await _authService.saveCredentials(isRememberMe: true, uid: user.id);
        } else {
          await _authService.clearCredentials();
        }
        await _navigateBasedOnUserRole(user.id);
      }
    } on AuthException {
      showFeedbackSnackbar(
        Get.context!,
        'error_login_failed'.tr,
        isError: true,
      );
    } catch (e) {
      showFeedbackSnackbar(Get.context!, e.toString(), isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
