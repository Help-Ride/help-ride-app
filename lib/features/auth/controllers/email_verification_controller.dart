import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:help_ride/core/routes/app_routes.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'package:help_ride/shared/services/api_exception.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/services/token_storage.dart';
import '../../../shared/models/user.dart';
import '../routes/auth_routes.dart';
import '../services/auth_api.dart';

class EmailVerificationController extends GetxController {
  final otp = ''.obs;
  final isSending = false.obs;
  final isVerifying = false.obs;
  final error = RxnString();
  final message = RxnString();

  final _email = ''.obs;
  var _autoSent = false;

  late final TokenStorage _tokenStorage;
  late final AuthApi _authApi;

  String get email => _email.value;
  bool get canVerify => otp.value.trim().length == 6 && !isVerifying.value;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    _tokenStorage = TokenStorage();
    final apiClient = await ApiClient.create();
    _authApi = AuthApi(apiClient);

    final argEmail = (Get.arguments is Map) ? Get.arguments['email'] : null;
    final session = Get.find<SessionController>();
    _email.value = (argEmail?.toString().trim().isNotEmpty ?? false)
        ? argEmail.toString().trim()
        : (session.user.value?.email ?? '');

    if (_email.value.isEmpty) {
      error.value = 'Missing email for verification.';
      return;
    }
    _autoSendIfReady();
  }

  @override
  void onReady() {
    super.onReady();
    _autoSendIfReady();
  }

  void _autoSendIfReady() {
    if (_autoSent || _email.value.isEmpty) return;
    _autoSent = true;
    sendOtp();
  }

  void setOtp(String value) {
    otp.value = value;
    error.value = null;
  }

  Future<void> sendOtp() async {
    if (isSending.value || _email.value.isEmpty) return;
    isSending.value = true;
    error.value = null;
    message.value = null;

    try {
      await _authApi.sendVerifyEmailOtp(email: _email.value);
      message.value = 'We sent a verification code to your email.';
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      isSending.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (!canVerify) {
      error.value = 'Enter the 6-digit code.';
      return;
    }

    isVerifying.value = true;
    error.value = null;
    message.value = null;

    try {
      final result = await _authApi.verifyEmailOtp(
        email: _email.value,
        otp: otp.value.trim(),
      );

      final tokens = result?.tokens;
      if (tokens != null) {
        await _tokenStorage.saveAccessToken(tokens.accessToken);
        await _tokenStorage.saveAuthProvider('email');
        if (tokens.refreshToken != null) {
          await _tokenStorage.saveRefreshToken(tokens.refreshToken!);
        } else {
          await _tokenStorage.deleteRefreshToken();
        }

        final session = Get.find<SessionController>();
        final userJson = result?.user;
        if (userJson != null) {
          if (!userJson.containsKey('emailVerified')) {
            userJson['emailVerified'] = true;
          }
          session.user.value = User.fromJson(userJson);
          session.status.value = SessionStatus.authenticated;
        } else {
          await session.bootstrap();
        }
        Get.offAllNamed(AppRoutes.shell);
      } else {
        message.value = 'Email verified. Please sign in.';
        Get.offAllNamed(AuthRoutes.login);
      }
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
