import 'package:get/get.dart';
import '../services/token_storage.dart';
import '../../features/auth/services/auth_api.dart';
import '../services/api_client.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

class SessionController extends GetxController {
  final status = SessionStatus.unknown.obs;
  final user = Rxn<Map<String, dynamic>>();

  String? get email => user.value?['email'];
  String? get role => user.value?['role']; // driver / passenger
  String? get userId => user.value?['id'];

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
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      status.value = SessionStatus.unauthenticated;
      return;
    }

    try {
      final me = await _authApi.me(); // calls GET /auth/me with Bearer token
      user.value = me;
      status.value = SessionStatus.authenticated;
    } catch (_) {
      await _tokenStorage.clear();
      status.value = SessionStatus.unauthenticated;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    user.value = null;
    status.value = SessionStatus.unauthenticated;
  }
}
