import 'package:get/get.dart';
import 'package:email_validator/email_validator.dart';

class AuthController extends GetxController {
  final email = ''.obs;
  final password = ''.obs;

  final isLoading = false.obs;
  final error = RxnString();

  bool get isEmailValid => EmailValidator.validate(email.value.trim());
  bool get isPasswordValid => password.value.trim().length >= 8;
  bool get canSubmit => isEmailValid && isPasswordValid && !isLoading.value;

  void setEmail(String v) {
    email.value = v;
    error.value = null;
  }

  void setPassword(String v) {
    password.value = v;
    error.value = null;
  }

  Future<void> loginWithEmail() async {
    if (!canSubmit) {
      error.value = 'Enter a valid email + password (8+ chars).';
      return;
    }

    isLoading.value = true;
    error.value = null;

    try {
      print(
        'Logging in with email=${email.value} and password=${password.value}',
      );
      // TODO: call API here
      await Future.delayed(const Duration(milliseconds: 800));

      // TODO: store token + navigate
      Get.offAllNamed('/home');
    } catch (e) {
      error.value = 'Login failed. Try again.';
    } finally {
      isLoading.value = false;
    }
  }
}
