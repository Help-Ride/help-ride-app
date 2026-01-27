import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'notifications_api.dart';
import 'token_storage.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final TokenStorage _tokenStorage = TokenStorage();

  NotificationsApi? _api;
  StreamSubscription<String>? _tokenRefreshSub;
  Timer? _retryTimer;
  bool _initialized = false;
  bool _registering = false;
  int _retryAttempts = 0;
  static const int _maxRetryAttempts = 5;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _messaging.setAutoInitEnabled(true);
    await _requestPermission();

    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_handleTokenRefresh);

    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        debugPrint('FCM foreground message: ${message.messageId}');
      }
    });
    final token = await _safeGetToken();
    if (token != null && token.trim().isNotEmpty) {
      await _tokenStorage.saveCachedDeviceToken(token.trim());
      _log('FCM token cached on init.');
    } else {
      _log('FCM token not available on init.');
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    _retryTimer?.cancel();
  }

  Future<void> registerDeviceTokenIfNeeded() async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) return;

    final token = await _resolveToken();
    if (token == null || token.trim().isEmpty) {
      _scheduleRetry();
      return;
    }

    final registered = await _tokenStorage.getDeviceToken();
    if (registered != null && registered.trim() == token.trim()) {
      _log('FCM token already registered.');
      return;
    }

    await _registerToken(token.trim());
    _resetRetryAttempts();
  }

  Future<void> unregisterDeviceTokenIfNeeded() async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      await _tokenStorage.deleteDeviceToken();
      await _tokenStorage.deleteCachedDeviceToken();
      return;
    }

    final token =
        await _tokenStorage.getDeviceToken() ??
        await _tokenStorage.getCachedDeviceToken();
    if (token == null || token.trim().isEmpty) return;

    await _unregisterToken(token.trim());
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      _log('Notification permission: ${settings.authorizationStatus.name}');

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {
      // Ignore permission errors; app can still run without notifications.
    }
  }

  Future<void> _handleTokenRefresh(String token) async {
    if (token.trim().isEmpty) return;

    await _tokenStorage.saveCachedDeviceToken(token.trim());
    _resetRetryAttempts();

    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      return;
    }

    await _registerToken(token.trim());
  }

  Future<void> _registerToken(String token) async {
    if (_registering) return;
    _registering = true;
    try {
      final api = await _getApi();
      await api.registerToken(token: token, platform: _platform());
      await _tokenStorage.saveDeviceToken(token);
      _log('FCM token registered with backend.');
    } finally {
      _registering = false;
    }
  }

  Future<void> _unregisterToken(String token) async {
    try {
      final api = await _getApi();
      await api.unregisterToken(token: token, skipAuthLogout: true);
    } catch (_) {
      // Best-effort unregister; don't block logout flows.
    }
    await _tokenStorage.deleteDeviceToken();
    await _tokenStorage.deleteCachedDeviceToken();
    try {
      await _messaging.deleteToken();
    } catch (_) {
      // ignore
    }
  }

  Future<NotificationsApi> _getApi() async {
    final existing = _api;
    if (existing != null) return existing;
    final client = await ApiClient.create();
    final api = NotificationsApi(client);
    _api = api;
    return api;
  }

  String _platform() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  Future<String?> _resolveToken() async {
    final token = await _safeGetToken();
    if (token != null && token.trim().isNotEmpty) return token.trim();
    final cached = await _tokenStorage.getCachedDeviceToken();
    if (cached != null && cached.trim().isNotEmpty) return cached.trim();
    return null;
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (_retryAttempts >= _maxRetryAttempts) {
      _log('FCM token missing; retry limit reached.');
      return;
    }
    _retryAttempts += 1;
    _log('FCM token missing; retry $_retryAttempts/$_maxRetryAttempts scheduled.');
    _retryTimer = Timer(const Duration(seconds: 5), () {
      registerDeviceTokenIfNeeded();
    });
  }

  void _resetRetryAttempts() {
    _retryAttempts = 0;
    _retryTimer?.cancel();
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[Push] $message');
    }
  }

  Future<String?> _safeGetToken() async {
    try {
      return await _messaging.getToken();
    } on FirebaseException catch (e) {
      if (e.code == 'apns-token-not-set') {
        _log('APNs token not set yet; will retry.');
        return null;
      }
      _log('FCM getToken error: ${e.code}');
      return null;
    } catch (_) {
      _log('FCM getToken unknown error.');
      return null;
    }
  }
}
