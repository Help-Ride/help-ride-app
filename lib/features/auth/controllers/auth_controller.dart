import 'package:get/get.dart';
import 'package:email_validator/email_validator.dart';
import 'package:help_ride/core/routes/app_routes.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/services/token_storage.dart';
import '../services/auth_api.dart';

class AuthController extends GetxController {
  final email = 'patel.rishi3001@gmail.com'.obs;
  final password = 'StrongPass123!'.obs;

  final isLoading = false.obs;
  final error = RxnString();

  late final TokenStorage _tokenStorage;
  late final AuthApi _authApi;

  @override
  Future<void> onInit() async {
    super.onInit();
    _tokenStorage = TokenStorage();
    final client = await ApiClient.create();
    _authApi = AuthApi(client);
  }

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
      final token = await _authApi.loginWithEmail(
        email: email.value.trim(),
        password: password.value.trim(),
      );

      await _tokenStorage.saveAccessToken(token);

      final session = Get.find<SessionController>();
      await session.bootstrap();

      Get.offAllNamed(AppRoutes.home);
      Get.offAllNamed(AppRoutes.shell);
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  String _prettyError(Object e) {
    final s = e.toString();
    if (s.contains('401')) return 'Invalid email or password.';
    if (s.contains('404'))
      return 'Login API not found. Backend missing /auth/login.';
    return 'Login failed. ${s.length > 120 ? s.substring(0, 120) : s}';
  }
}
