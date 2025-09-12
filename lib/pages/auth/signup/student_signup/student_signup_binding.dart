import 'package:get/get.dart';
import 'package:unicurve/pages/auth/signup/student_signup/student_signup_controller.dart';

class SignupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SignupController>(() => SignupController());
  }
}
