import 'package:get/get.dart';
import '../../features/profile/Models/user.dart';
import '../models/user.dart';
import '../services/token_storage.dart';
import '../../features/auth/services/auth_api.dart';
import '../services/api_client.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

class SessionController extends GetxController {
  final Rx<SessionStatus> status = SessionStatus.unknown.obs;
  final Rxn<EditUser> user = Rxn<EditUser>();

  late final TokenStorage _tokenStorage;
  late final AuthApi _authApi;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    _tokenStorage = TokenStorage();

    final client = await ApiClient.create();
    _authApi = AuthApi(client);

    await bootstrap();
  }

  // ---------------- BOOTSTRAP ----------------

  Future<void> bootstrap() async {
    status.value = SessionStatus.unknown;

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      _unauthenticated();
      return;
    }

    try {
      final meJson = await _authApi.me();
      user.value = EditUser.fromJson(meJson);
      status.value = SessionStatus.authenticated;
    } catch (e) {
      await _tokenStorage.clear();
      _unauthenticated();
    }
  }

  // ---------------- UPDATE USER ----------------

  void updateUser({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
  }) {
    final currentUser = user.value;
    if (currentUser == null) return;

    user.value = currentUser.copyWith(
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
    );
  }

  // ---------------- LOGOUT ----------------

  Future<void> logout() async {
    await _tokenStorage.clear();
    _unauthenticated();
  }

  void _unauthenticated() {
    user.value = null;
    status.value = SessionStatus.unauthenticated;
  }

  // ---------------- GETTERS ----------------

  bool get isAuthenticated =>
      status.value == SessionStatus.authenticated;

  bool get isDriver => user.value?.driverProfile != null;

  String get roleDefault => user.value?.roleDefault ?? 'passenger';

  String get name => user.value?.name ?? '—';

  String get email => user.value?.email ?? '—';

  String get phone => user.value?.name ?? '—';

  String? get avatarUrl => user.value?.avatarUrl;
}
