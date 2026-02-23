import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:help_ride/shared/services/api_exception.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/utils/input_validators.dart';
import '../routes/auth_routes.dart';
import '../services/auth_api.dart';

class PasswordResetController extends GetxController {
  final email = ''.obs;
  final otp = ''.obs;
  final newPassword = ''.obs;

  final isReady = false.obs;
  final otpSent = false.obs;
  final isSendingOtp = false.obs;
  final isResetting = false.obs;
  final error = RxnString();
  final message = RxnString();

  late final AuthApi _authApi;

  String? get emailError => InputValidators.email(email.value);
  String? get otpError => InputValidators.otpCode(otp.value);
  String? get newPasswordError => InputValidators.password(newPassword.value);

  bool get canSendOtp =>
      isReady.value && emailError == null && !isSendingOtp.value;
  bool get canResetPassword =>
      isReady.value &&
      emailError == null &&
      otpError == null &&
      newPasswordError == null &&
      !isResetting.value;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    final apiClient = await ApiClient.create();
    _authApi = AuthApi(apiClient);

    final argEmail = (Get.arguments is Map) ? Get.arguments['email'] : null;
    if (argEmail is String && argEmail.trim().isNotEmpty) {
      email.value = argEmail.trim();
    }

    isReady.value = true;
  }

  void setEmail(String value) {
    email.value = value;
    error.value = null;
  }

  void setOtp(String value) {
    otp.value = value;
    error.value = null;
  }

  void setNewPassword(String value) {
    newPassword.value = value;
    error.value = null;
  }

  Future<void> sendOtp() async {
    if (!canSendOtp) {
      error.value = emailError ?? 'Please enter a valid email.';
      return;
    }

    if (isSendingOtp.value) return;

    isSendingOtp.value = true;
    error.value = null;
    message.value = null;

    try {
      await _authApi.sendPasswordResetOtp(email: email.value.trim());
      otpSent.value = true;
      message.value = 'Password reset code sent to your email.';
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      isSendingOtp.value = false;
    }
  }

  Future<void> resetPassword() async {
    if (!canResetPassword) {
      error.value =
          emailError ??
          otpError ??
          newPasswordError ??
          'Please fix highlighted fields.';
      return;
    }

    isResetting.value = true;
    error.value = null;
    message.value = null;

    try {
      await _authApi.verifyPasswordResetOtp(
        email: email.value.trim(),
        otp: otp.value.trim(),
        newPassword: newPassword.value.trim(),
      );

      message.value = 'Password reset successful. Please sign in.';
      Get.offAllNamed(AuthRoutes.login);
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      isResetting.value = false;
    }
  }

  String _prettyError(Object e) {
    if (e is DioException && e.error is ApiException) {
      return (e.error as ApiException).message;
    }

    if (e is DioException) {
      return 'Network error. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }
}
