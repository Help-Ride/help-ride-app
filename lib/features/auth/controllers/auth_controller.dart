import 'package:get/get.dart';
import 'package:email_validator/email_validator.dart';
import 'package:help_ride/core/routes/app_routes.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/services/token_storage.dart';
import '../services/auth_api.dart';
import '../services/oauth_api.dart';
import '../services/google_oauth_service.dart';

class AuthController extends GetxController {
  final email = ''.obs;
  final password = ''.obs;

  final isLoading = false.obs; // email/password loading
  final oauthLoading = false.obs; // google loading
  final error = RxnString();

  late final TokenStorage _tokenStorage;
  late final AuthApi _authApi;
  late final OAuthApi _oauthApi;
  late final GoogleOAuthService _googleOAuth;

  bool get isEmailValid => EmailValidator.validate(email.value.trim());
  bool get isPasswordValid => password.value.trim().length >= 8;

  bool get canSubmit =>
      isEmailValid &&
      isPasswordValid &&
      !isLoading.value &&
      !oauthLoading.value;

  @override
  Future<void> onInit() async {
    super.onInit();

    _tokenStorage = TokenStorage();

    final apiClient = await ApiClient.create();

    _authApi = AuthApi(apiClient);
    _oauthApi = OAuthApi(apiClient);

    _googleOAuth = GoogleOAuthService();
  }

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
      final token = await _authApi.loginWithEmail(
        email: email.value.trim(),
        password: password.value.trim(),
      );

      await _tokenStorage.saveAccessToken(token);

      final session = Get.find<SessionController>();
      await session.bootstrap();

      // ✅ only one navigation target
      Get.offAllNamed(AppRoutes.shell);
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

      final token = await _oauthApi.oauthLogin(
        provider: 'google',
        providerUserId: acc.id,
        email: acc.email,
        name: acc.name ?? 'User',
        avatarUrl: acc.avatarUrl,
      );

      await _tokenStorage.saveAccessToken(token);

      final session = Get.find<SessionController>();
      await session.bootstrap();

      Get.offAllNamed(AppRoutes.shell);
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      oauthLoading.value = false;
    }
  }

  String _prettyError(Object e) {
    final s = e.toString();
    if (s.contains('401')) return 'Invalid credentials.';
    if (s.contains('403')) return 'Access denied.';
    if (s.contains('404')) return 'Auth API not found.';
    if (s.contains('SocketException') || s.contains('Connection')) {
      return 'Network error. Check internet or base URL.';
    }
    return 'Login failed. ${s.length > 160 ? s.substring(0, 160) : s}';
  }
}
