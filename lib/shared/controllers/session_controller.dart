import 'package:get/get.dart';
import 'package:help_ride/shared/models/user.dart';
import '../services/token_storage.dart';
import '../../features/auth/services/auth_api.dart';
import '../services/api_client.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

class SessionController extends GetxController {
  final status = SessionStatus.unknown.obs;
  final user = Rxn<User>();
  final _authProvider = RxnString();

  late final TokenStorage _tokenStorage;
  late final AuthApi _authApi;

  @override
  Future<void> onInit() async {
    super.onInit();
    _tokenStorage = TokenStorage();

    final client = await ApiClient.create();
    _authApi = AuthApi(client);

    await bootstrap();
  }

  Future<void> bootstrap() async {
    status.value = SessionStatus.unknown;

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      user.value = null;
      _authProvider.value = null;
      status.value = SessionStatus.unauthenticated;
      return;
    }

    _authProvider.value = await _tokenStorage.getAuthProvider();

    try {
      final meJson = await _authApi.me(); // Map<String, dynamic>
      user.value = User.fromJson(meJson); // ✅ parse
      if (user.value?.authProvider != null &&
          user.value!.authProvider!.trim().isNotEmpty) {
        _authProvider.value = user.value!.authProvider!.trim();
      }
      status.value = SessionStatus.authenticated;
    } catch (_) {
      await _tokenStorage.clear();
      user.value = null;
      _authProvider.value = null;
      status.value = SessionStatus.unauthenticated;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    user.value = null;
    _authProvider.value = null;
    status.value = SessionStatus.unauthenticated;
  }

  // Handy getters
  bool get isDriver => user.value?.driverProfile != null;
  bool get isEmailVerified => user.value?.emailVerified ?? false;
  String get authProvider => _authProvider.value ?? 'email';
  bool get requiresEmailVerification =>
      authProvider == 'email' && !isEmailVerified;
  String get roleDefault => user.value?.roleDefault ?? 'passenger';
  String get name => user.value?.name ?? '—';
  String get email => user.value?.email ?? '—';
}
