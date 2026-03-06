import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:help_ride/core/routes/app_routes.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'package:help_ride/shared/services/api_exception.dart';
import 'package:help_ride/shared/services/api_client.dart';
import 'package:help_ride/shared/services/token_storage.dart';
import 'package:help_ride/shared/utils/input_validators.dart';
import 'package:help_ride/shared/utils/phone_number_utils.dart';
import '../services/auth_api.dart';

class PhoneVerificationController extends GetxController {
  final otp = ''.obs;
  final isSending = false.obs;
  final isVerifying = false.obs;
  final error = RxnString();
  final message = RxnString();

  final _phone = ''.obs;
  final _email = ''.obs;
  var _autoSent = false;
  bool _shouldAutoSend = true;

  late final TokenStorage _tokenStorage;
  late final AuthApi _authApi;

  String get phone => _phone.value;
  String get maskedPhone => PhoneNumberUtils.maskForDisplay(_phone.value);
  String get email => _email.value;
  String? get otpError => InputValidators.otpCode(otp.value);
  bool get canVerify => otpError == null && !isVerifying.value;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    _tokenStorage = TokenStorage();
    final apiClient = await ApiClient.create();
    _authApi = AuthApi(apiClient);

    final args = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments)
        : const <String, dynamic>{};
    _phone.value = (args['phone']?.toString().trim() ?? '');
    _email.value = (args['email']?.toString().trim() ?? '');
    _shouldAutoSend = args['autoSend'] != false;

    if (_phone.value.isEmpty) {
      error.value = 'Missing phone number for verification.';
      return;
    }

    if (_shouldAutoSend) {
      _autoSendIfReady();
    }
  }

  @override
  void onReady() {
    super.onReady();
    if (_shouldAutoSend) {
      _autoSendIfReady();
    }
  }

  void _autoSendIfReady() {
    if (_autoSent || _phone.value.isEmpty) return;
    _autoSent = true;
    sendOtp();
  }

  void setOtp(String value) {
    otp.value = value;
    error.value = null;
  }

  Future<void> sendOtp() async {
    if (isSending.value || _phone.value.isEmpty) return;
    isSending.value = true;
    error.value = null;
    message.value = null;

    try {
      await _authApi.sendVerifyPhoneOtp(phone: _phone.value);
      message.value = 'We texted a verification code to $maskedPhone.';
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      isSending.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (!canVerify) {
      error.value = otpError ?? 'Please fix highlighted fields.';
      return;
    }

    isVerifying.value = true;
    error.value = null;
    message.value = null;

    try {
      final result = await _authApi.verifyPhoneOtp(
        phone: _phone.value,
        otp: otp.value.trim(),
      );

      final tokens = result?.tokens;
      if (tokens == null) {
        throw Exception('Missing access token in phone verification response');
      }

      await _tokenStorage.saveAccessToken(tokens.accessToken);
      await _tokenStorage.saveAuthProvider('email');
      if (tokens.refreshToken != null) {
        await _tokenStorage.saveRefreshToken(tokens.refreshToken!);
      } else {
        await _tokenStorage.deleteRefreshToken();
      }

      final session = Get.find<SessionController>();
      await session.bootstrap();

      Get.offAllNamed(AppRoutes.shell);
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      isVerifying.value = false;
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
