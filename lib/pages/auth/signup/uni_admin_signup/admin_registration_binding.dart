import 'package:get/get.dart';
import 'package:unicurve/pages/auth/signup/uni_admin_signup/uni_admin_registration_controller.dart';

class AdminRegistrationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminRegistrationController>(
      () => AdminRegistrationController(),
    );
  }
}
