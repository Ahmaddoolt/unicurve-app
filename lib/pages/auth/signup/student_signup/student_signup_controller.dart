import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/bottom_nativgation/student_bottom_bar/student_bottom_navigation_bar.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/data/services/auth_services.dart';
import 'package:unicurve/domain/models/student.dart';

class SignupController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final universityNumberController = TextEditingController();

  var isLoading = false.obs;
  var obscurePassword = true.obs;
  var obscureConfirmPassword = true.obs;

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

  Map<String, String>? selectedLocation;
  Map<String, dynamic>? selectedUniversity;
  Map<String, dynamic>? selectedMajor;

  List<dynamic> universities = [];
  List<dynamic> majors = [];

  var isUniversitiesLoading = false.obs;
  var isMajorsLoading = false.obs;

  Future<void> onLocationChanged(Map<String, String>? newValue) async {
    if (newValue == null || newValue['value'] == selectedLocation?['value']) {
      return;
    }

    selectedLocation = newValue;
    universities = [];
    majors = [];
    selectedUniversity = null;
    selectedMajor = null;
    update();

    isUniversitiesLoading.value = true;
    try {
      final response = await _authService.getUniversities(
        selectedLocation!['value']!,
      );
      universities = response;
    } catch (e) {
      showFeedbackSnackbar(
        Get.context!,
        'error_loading_universities'.trParams({
          'error': e.toString().replaceFirst('Exception: ', ''),
        }),
        isError: true,
      );
    } finally {
      isUniversitiesLoading.value = false;
      update();
    }
  }

  Future<void> onUniversityChanged(dynamic value) async {
    selectedUniversity = value as Map<String, dynamic>?;
    majors = [];
    selectedMajor = null;
    update();

    if (selectedUniversity != null) {
      isMajorsLoading.value = true;
      try {
        final response = await _authService.getMajors(
          selectedUniversity!['id'],
        );
        majors = response;
      } catch (e) {
        showFeedbackSnackbar(
          Get.context!,
          'error_loading_majors'.trParams({
            'error': e.toString().replaceFirst('Exception: ', ''),
          }),
          isError: true,
        );
      } finally {
        isMajorsLoading.value = false;
        update();
      }
    }
  }

  Future<bool> _checkUniqueUniversityNumber(
    String uniNumber,
    int universityId,
  ) async {
    try {
      final response =
          await Supabase.instance.client
              .from('students')
              .select('id')
              .eq('uni_number', uniNumber)
              .eq('university_id', universityId)
              .maybeSingle();
      return response == null;
    } catch (_) {
      return false;
    }
  }

  Future<void> signUp() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (selectedLocation == null ||
        selectedUniversity == null ||
        selectedMajor == null) {
      showFeedbackSnackbar(
        Get.context!,
        'error_select_uni_and_major'.tr,
        isError: true,
      );
      return;
    }

    final uniNumber = universityNumberController.text.trim();
    final universityId = selectedUniversity!['id'] as int;

    final isUnique = await _checkUniqueUniversityNumber(
      uniNumber,
      universityId,
    );
    if (!isUnique) {
      showFeedbackSnackbar(
        Get.context!,
        'error_uni_number_exists'.tr,
        isError: true,
      );
      return;
    }

    final student = Student(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      uniNumber: uniNumber,
      universityId: universityId,
      majorId: selectedMajor!['id'] as int,
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    isLoading.value = true;
    try {
      final userId = await _authService.signUp(student: student);
      if (userId != null) {
        Get.offAll(() => const StudentBottomBar());
      } else {
        throw Exception('error_user_creation_failed'.tr);
      }
    } on AuthException catch (e) {
      showFeedbackSnackbar(Get.context!, e.message, isError: true);
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
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    universityNumberController.dispose();
    super.onClose();
  }
}
