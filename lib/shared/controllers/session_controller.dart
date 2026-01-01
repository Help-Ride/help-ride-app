// import 'package:get/get.dart';
// import 'package:help_ride/shared/models/user.dart';
// import '../services/token_storage.dart';
// import '../../features/auth/services/auth_api.dart';
// import '../services/api_client.dart';
//
// enum SessionStatus { unknown, authenticated, unauthenticated }
//
// class SessionController extends GetxController {
//   final status = SessionStatus.unknown.obs;
//   final user = Rxn<User>();
//
//   late final TokenStorage _tokenStorage;
//   late final AuthApi _authApi;
//
//   @override
//   Future<void> onInit() async {
//     super.onInit();
//     _tokenStorage = TokenStorage();
//
//     final client = await ApiClient.create();
//     _authApi = AuthApi(client);
//
//     await bootstrap();
//   }
//
//   Future<void> bootstrap() async {
//     status.value = SessionStatus.unknown;
//
//     final token = await _tokenStorage.getAccessToken();
//     if (token == null || token.isEmpty) {
//       user.value = null;
//       status.value = SessionStatus.unauthenticated;
//       return;
//     }
//
//     try {
//       final meJson = await _authApi.me(); // Map<String, dynamic>
//       user.value = User.fromJson(meJson); // ✅ parse
//       status.value = SessionStatus.authenticated;
//     } catch (_) {
//       await _tokenStorage.clear();
//       user.value = null;
//       status.value = SessionStatus.unauthenticated;
//     }
//   }
//
//   Future<void> logout() async {
//     await _tokenStorage.clear();
//     user.value = null;
//     status.value = SessionStatus.unauthenticated;
//   }
//
//   // Handy getters
//   bool get isDriver => user.value?.driverProfile != null;
//   String get roleDefault => user.value?.roleDefault ?? 'passenger';
//   String get name => user.value?.name ?? '—';
//   String get email => user.value?.email ?? '—';
// }


import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:help_ride/shared/models/user.dart';
import '../services/token_storage.dart';
import '../../features/auth/services/auth_api.dart';
import '../services/api_client.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

class SessionController extends GetxController {
  final status = SessionStatus.unknown.obs;
  final user = Rxn<User>();

  /// 🔹 Onboarding flag
  final isOnboardingCompleted = false.obs;

  late final TokenStorage _tokenStorage;
  late final AuthApi _authApi;
  late final GetStorage _storage;

  static const _onboardingKey = 'onboarding_completed';

  @override
  Future<void> onInit() async {
    super.onInit();

    _storage = GetStorage();
    _tokenStorage = TokenStorage();

    final client = await ApiClient.create();
    _authApi = AuthApi(client);

    /// Load onboarding state
    isOnboardingCompleted.value =
        _storage.read(_onboardingKey) ?? false;

    await bootstrap();
  }

  Future<void> bootstrap() async {
    status.value = SessionStatus.unknown;

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      user.value = null;
      status.value = SessionStatus.unauthenticated;
      return;
    }

    try {
      final meJson = await _authApi.me();
      user.value = User.fromJson(meJson);
      status.value = SessionStatus.authenticated;
    } catch (_) {
      await _tokenStorage.clear();
      user.value = null;
      status.value = SessionStatus.unauthenticated;
    }
  }

  /// 🔹 Mark onboarding done
  Future<void> completeOnboarding() async {
    isOnboardingCompleted.value = true;
    await _storage.write(_onboardingKey, true);
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    user.value = null;
    status.value = SessionStatus.unauthenticated;
  }

  // Handy getters
  bool get isDriver => user.value?.driverProfile != null;
  String get roleDefault => user.value?.roleDefault ?? 'passenger';
  String get name => user.value?.name ?? '—';
  String get email => user.value?.email ?? '—';
}
