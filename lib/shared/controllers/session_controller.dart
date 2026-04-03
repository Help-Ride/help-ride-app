import 'dart:async';

import 'package:get/get.dart';
import 'package:help_ride/shared/models/user.dart';
import '../../core/routes/app_routes.dart';
import '../../features/auth/routes/auth_routes.dart';
import '../services/token_storage.dart';
import '../../features/auth/services/auth_api.dart';
import '../services/api_client.dart';
import '../services/location_sync_service.dart';
import '../services/push_notification_service.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

class RequiredVerificationRoute {
  RequiredVerificationRoute({required this.routeName, required this.arguments});

  final String routeName;
  final Map<String, dynamic> arguments;
}

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

    try {
      final client = await ApiClient.create();
      _authApi = AuthApi(client);
      await bootstrap();
    } catch (_) {
      user.value = null;
      _authProvider.value = null;
      status.value = SessionStatus.unauthenticated;
    }
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
      try {
        await PushNotificationService.instance.registerDeviceTokenIfNeeded();
      } catch (_) {
        // Best-effort token registration.
      }
      unawaited(
        LocationSyncService.instance.syncMyLocation(requestPermission: false),
      );
    } catch (_) {
      await _tokenStorage.clear();
      user.value = null;
      _authProvider.value = null;
      status.value = SessionStatus.unauthenticated;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      try {
        await _authApi.logout(refreshToken: refreshToken.trim());
      } catch (_) {
        // Best-effort revoke; proceed to clear local session.
      }
    }
    await clearLocalSession();
  }

  Future<void> clearLocalSession() async {
    await PushNotificationService.instance.unregisterDeviceTokenIfNeeded();
    await _tokenStorage.clear();
    user.value = null;
    _authProvider.value = null;
    status.value = SessionStatus.unauthenticated;
  }

  // Handy getters
  bool get isDriver => user.value?.driverProfile != null;
  bool get isEmailVerified => user.value?.emailVerified ?? false;
  bool get isPhoneVerified => user.value?.phoneVerified ?? false;
  String get authProvider => _authProvider.value ?? 'email';
  String get phoneValue => user.value?.phone?.trim() ?? '';
  String get pendingEmailValue => user.value?.pendingEmail?.trim() ?? '';
  String get pendingPhoneValue => user.value?.pendingPhone?.trim() ?? '';
  bool get requiresEmailVerification =>
      authProvider == 'email' && !isEmailVerified;
  String get roleDefault => user.value?.roleDefault ?? 'passenger';
  String get name => user.value?.name ?? '—';
  String get email => user.value?.email ?? '—';

  bool get hasVerifiedEmail => email.trim().isNotEmpty && isEmailVerified;
  bool get hasVerifiedPhone => phoneValue.isNotEmpty && isPhoneVerified;

  RequiredVerificationRoute? get nextRequiredVerification {
    if (status.value != SessionStatus.authenticated) return null;
    final currentUser = user.value;
    if (currentUser == null) return null;

    if (!hasVerifiedEmail) {
      final emailForVerification = pendingEmailValue.isNotEmpty
          ? pendingEmailValue
          : currentUser.email.trim();
      return RequiredVerificationRoute(
        routeName: AuthRoutes.verifyEmail,
        arguments: {
          'email': emailForVerification,
          'allowBackToLogin': false,
          'provider': authProvider,
        },
      );
    }

    if (!hasVerifiedPhone) {
      final phoneForVerification = pendingPhoneValue.isNotEmpty
          ? pendingPhoneValue
          : phoneValue;
      return RequiredVerificationRoute(
        routeName: AuthRoutes.verifyPhone,
        arguments: {
          'phone': phoneForVerification.isEmpty ? null : phoneForVerification,
          'email': currentUser.email.trim(),
          'provider': authProvider,
          'autoSend': phoneForVerification.isNotEmpty,
          'allowBackToLogin': false,
        },
      );
    }

    return null;
  }

  Future<void> openVerifiedAppDestination({
    Map<String, dynamic>? shellArguments,
    bool flushPendingNavigation = false,
  }) async {
    final requiredRoute = nextRequiredVerification;
    if (requiredRoute != null) {
      await Get.offAllNamed(
        requiredRoute.routeName,
        arguments: requiredRoute.arguments,
      );
      return;
    }

    await Get.offAllNamed(AppRoutes.shell, arguments: shellArguments);
    if (flushPendingNavigation) {
      await PushNotificationService.instance.flushPendingNavigation();
    }
  }
}
