import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:email_validator/email_validator.dart';
import 'package:help_ride/core/routes/app_routes.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'package:help_ride/shared/services/api_exception.dart';
import '../routes/auth_routes.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/services/token_storage.dart';
import '../services/auth_api.dart';
import '../services/oauth_api.dart';
import '../services/google_oauth_service.dart';

class AuthController extends GetxController {
  final email = ''.obs;
  final password = ''.obs;
  final name = ''.obs;

  final isLoading = false.obs; // email/password loading
  final oauthLoading = false.obs; // google loading
  final error = RxnString();

  // prevents crash if user taps before init completes
  final isReady = false.obs;

  late final TokenStorage _tokenStorage;
  late final AuthApi _authApi;
  late final OAuthApi _oauthApi;
  late final GoogleOAuthService _googleOAuth;

  bool get isEmailValid => EmailValidator.validate(email.value.trim());
  bool get isPasswordValid => password.value.trim().length >= 8;

  bool get canSubmit =>
      isReady.value &&
      isEmailValid &&
      isPasswordValid &&
      !isLoading.value &&
      !oauthLoading.value;

  bool get canRegister => canSubmit;

  @override
  void onInit() {
    super.onInit();
    _init(); // don’t make onInit async
  }

  Future<void> _init() async {
    _tokenStorage = TokenStorage();
    final apiClient = await ApiClient.create();
    _authApi = AuthApi(apiClient);
    _oauthApi = OAuthApi(apiClient);
    _googleOAuth = GoogleOAuthService();
    isReady.value = true;
  }

  void setEmail(String v) {
    email.value = v;
    error.value = null;
  }

  void setPassword(String v) {
    password.value = v;
    error.value = null;
  }

  void setName(String v) {
    name.value = v;
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
      final result = await _authApi.loginWithEmail(
        email: email.value.trim(),
        password: password.value.trim(),
      );

      if (result.accessToken != null &&
          result.accessToken!.trim().isNotEmpty) {
        await _tokenStorage.saveAccessToken(result.accessToken!.trim());
        await _tokenStorage.saveAuthProvider('email');
        if (result.refreshToken != null &&
            result.refreshToken!.trim().isNotEmpty) {
          await _tokenStorage.saveRefreshToken(result.refreshToken!.trim());
        } else {
          await _tokenStorage.deleteRefreshToken();
        }
      }

      if (result.otpSent || result.accessToken == null) {
        Get.offAllNamed(
          AuthRoutes.verifyEmail,
          arguments: {'email': email.value.trim()},
        );
        return;
      }

      final session = Get.find<SessionController>();
      await session.bootstrap();

      if (!session.requiresEmailVerification) {
        Get.offAllNamed(AppRoutes.shell);
      } else {
        Get.offAllNamed(
          AuthRoutes.verifyEmail,
          arguments: {'email': email.value.trim()},
        );
      }
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    if (isLoading.value || oauthLoading.value) return;

    oauthLoading.value = true;
    error.value = null;

    try {
      final acc = await _googleOAuth.signIn();
      if (acc == null) return; // user cancelled

      final tokens = await _oauthApi.oauthLogin(
        provider: 'google',
        providerUserId: acc.id,
        email: acc.email,
        name: acc.name ?? 'User',
        avatarUrl: acc.avatarUrl,
      );

      await _tokenStorage.saveAccessToken(tokens.accessToken);
      await _tokenStorage.saveAuthProvider('google');
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
      oauthLoading.value = false;
    }
  }

  Future<void> registerWithEmail() async {
    if (!canRegister) {
      error.value = 'Enter a valid email + password (8+ chars).';
      return;
    }

    isLoading.value = true;
    error.value = null;

    try {
      final result = await _authApi.registerWithEmail(
        email: email.value.trim(),
        password: password.value.trim(),
        name: name.value.trim().isEmpty ? null : name.value.trim(),
      );

      if (result.accessToken != null &&
          result.accessToken!.trim().isNotEmpty) {
        await _tokenStorage.saveAccessToken(result.accessToken!.trim());
        await _tokenStorage.saveAuthProvider('email');
        if (result.refreshToken != null &&
            result.refreshToken!.trim().isNotEmpty) {
          await _tokenStorage.saveRefreshToken(result.refreshToken!.trim());
        } else {
          await _tokenStorage.deleteRefreshToken();
        }
      }

      if (result.otpSent || result.accessToken == null) {
        Get.offAllNamed(
          AuthRoutes.verifyEmail,
          arguments: {'email': email.value.trim()},
        );
        return;
      }

      final session = Get.find<SessionController>();
      await session.bootstrap();

      if (!session.requiresEmailVerification) {
        Get.offAllNamed(AppRoutes.shell);
      } else {
        Get.offAllNamed(
          AuthRoutes.verifyEmail,
          arguments: {'email': email.value.trim()},
        );
      }
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  String _prettyError(Object e) {
    // ✅ Our normalized API error
    if (e is DioException && e.error is ApiException) {
      return (e.error as ApiException).message;
    }

    // ✅ Network / unexpected issues
    if (e is DioException) {
      return 'Network error. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }
}
