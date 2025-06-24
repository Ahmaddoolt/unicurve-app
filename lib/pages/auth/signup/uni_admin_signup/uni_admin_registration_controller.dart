import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/data/services/auth_services.dart';
import 'package:unicurve/domain/models/uni_admin_request.dart';

class AdminRegistrationController extends GetxController {
  final PageController pageController = PageController();
  final GlobalKey<FormState> adminFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> universityFormKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController positionController = TextEditingController();
  final TextEditingController universityNameController =
      TextEditingController();
  final TextEditingController universityShortNameController =
      TextEditingController();

  final AuthService _authService = AuthService();
  var isLoading = false.obs;
  var currentPageIndex = 0.obs;
  var isPasswordObscured = true.obs;
  var isConfirmPasswordObscured = true.obs;

  final List<Map<String, String>> translatableLocations = [
    {'key': 'country_algeria', 'value': 'Algeria'},
    {'key': 'country_bahrain', 'value': 'Bahrain'},
    {'key': 'country_egypt', 'value': 'Egypt'},
    {'key': 'country_iraq', 'value': 'Iraq'},
    {'key': 'country_jordan', 'value': 'Jordan'},
    {'key': 'country_kuwait', 'value': 'Kuwait'},
    {'key': 'country_lebanon', 'value': 'Lebanon'},
    {'key': 'country_libya', 'value': 'Libya'},
    {'key': 'country_morocco', 'value': 'Morocco'},
    {'key': 'country_oman', 'value': 'Oman'},
    {'key': 'country_palestine', 'value': 'Palestine'},
    {'key': 'country_qatar', 'value': 'Qatar'},
    {'key': 'country_saudi_arabia', 'value': 'Saudi Arabia'},
    {'key': 'country_sudan', 'value': 'Sudan'},
    {'key': 'country_syria', 'value': 'Syria'},
    {'key': 'country_tunisia', 'value': 'Tunisia'},
    {'key': 'country_uae', 'value': 'United Arab Emirates'},
    {'key': 'country_yemen', 'value': 'Yemen'},
    {'key': 'country_austria', 'value': 'Austria'},
    {'key': 'country_belgium', 'value': 'Belgium'},
    {'key': 'country_denmark', 'value': 'Denmark'},
    {'key': 'country_finland', 'value': 'Finland'},
    {'key': 'country_france', 'value': 'France'},
    {'key': 'country_germany', 'value': 'Germany'},
    {'key': 'country_ireland', 'value': 'Ireland'},
    {'key': 'country_italy', 'value': 'Italy'},
    {'key': 'country_netherlands', 'value': 'Netherlands'},
    {'key': 'country_norway', 'value': 'Norway'},
    {'key': 'country_poland', 'value': 'Poland'},
    {'key': 'country_spain', 'value': 'Spain'},
    {'key': 'country_sweden', 'value': 'Sweden'},
    {'key': 'country_switzerland', 'value': 'Switzerland'},
    {'key': 'country_uk', 'value': 'United Kingdom'},
    {'key': 'country_australia', 'value': 'Australia'},
    {'key': 'country_canada', 'value': 'Canada'},
    {'key': 'country_new_zealand', 'value': 'New Zealand'},
    {'key': 'country_usa', 'value': 'United States'},
    {'key': 'country_other', 'value': 'Other'},
  ];

  var selectedUniversityType = Rxn<String>();
  var selectedUniversityLocation = Rxn<Map<String, String>>();

  @override
  void onInit() {
    super.onInit();
    pageController.addListener(() {
      if (pageController.page?.round() != currentPageIndex.value) {
        currentPageIndex.value = pageController.page!.round();
      }
    });
  }

  @override
  void onClose() {
    pageController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    positionController.dispose();
    universityNameController.dispose();
    universityShortNameController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordObscured.value = !isPasswordObscured.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordObscured.value = !isConfirmPasswordObscured.value;
  }

  void handleBackPress() {
    if (currentPageIndex.value == 1) {
      goToPreviousPage();
    } else {
      Get.back();
    }
  }

  void goToNextPage() {
    if (adminFormKey.currentState?.validate() ?? false) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void goToPreviousPage() {
    pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> submitRequest() async {
    final bool adminFormValid = adminFormKey.currentState?.validate() ?? false;
    final bool universityFormValid =
        universityFormKey.currentState?.validate() ?? false;

    if (!adminFormValid || !universityFormValid) {
      showFeedbackSnackbar(
        Get.context!,
        'error_fix_before_submit'.tr,
        isError: true,
      );
      return;
    }

    final uniAdmin = UniAdmin(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      phoneNumber: phoneNumberController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      position: positionController.text.trim(),
      universityName: universityNameController.text.trim(),
      universityShortName: universityShortNameController.text.trim(),
      universityType: selectedUniversityType.value!,
      universityLocation: selectedUniversityLocation.value!['value']!,
    );

    isLoading.value = true;
    try {
      await _authService.submitAdminRequest(uniAdmin: uniAdmin);
      showFeedbackSnackbar(Get.context!, 'success_request_submitted'.tr);
      Get.back();
    } on AuthException catch (e) {
      showFeedbackSnackbar(Get.context!, e.message, isError: true);
    } catch (e) {
      showFeedbackSnackbar(
        Get.context!,
        'error_unexpected'.trParams({'error': e.toString()}),
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
