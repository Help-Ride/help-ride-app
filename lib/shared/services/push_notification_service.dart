import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../features/driver/routes/driver_routes.dart';
import '../../features/rides/routes/rides_routes.dart';
import 'api_client.dart';
import 'notifications_api.dart';
import 'token_storage.dart';

@pragma('vm:entry-point')
void _onBackgroundNotificationTap(NotificationResponse response) {}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final TokenStorage _tokenStorage = TokenStorage();
  final StreamController<String> _rideOfferController =
      StreamController<String>.broadcast();

  NotificationsApi? _api;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _messageOpenedSub;
  Timer? _retryTimer;
  bool _initialized = false;
  bool _registering = false;
  bool _localNotificationReady = false;
  int _retryAttempts = 0;
  static const int _maxRetryAttempts = 5;
  static const Duration _tokenRefreshInterval = Duration(days: 1);

  static const AndroidNotificationChannel _offersChannel =
      AndroidNotificationChannel(
        'driver_ride_offers',
        'Driver Ride Offers',
        description: 'Ride offer alerts for drivers',
        importance: Importance.max,
      );
  static const Set<String> _rideRequestKinds = {
    'ride_request_created',
    'ride_request_created_nearby',
  };
  static const Set<String> _rideCreatedKinds = {'ride_created'};

  Map<String, String>? _pendingNavigationTarget;
  bool _navigationInFlight = false;

  Stream<String> get rideOfferStream => _rideOfferController.stream;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _messaging.setAutoInitEnabled(true);
    await _requestPermission();
    await _initLocalNotifications();

    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_handleTokenRefresh);
    _foregroundSub = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _messageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleMessageOpenedApp,
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

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
    await _foregroundSub?.cancel();
    await _messageOpenedSub?.cancel();
    _retryTimer?.cancel();
    await _rideOfferController.close();
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
    final registeredAt = await _tokenStorage.getDeviceTokenRegisteredAt();
    final sameToken = registered != null && registered.trim() == token.trim();
    if (sameToken && !_isRegistrationStale(registeredAt)) {
      _log('FCM token already registered.');
      return;
    }
    if (sameToken) {
      _log('FCM token unchanged but registration refresh is due.');
    }

    try {
      await _registerToken(token.trim());
      _resetRetryAttempts();
    } catch (_) {
      _log('FCM token registration failed; scheduling retry.');
      _scheduleRetry();
    }
  }

  Future<void> unregisterDeviceTokenIfNeeded() async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      await _tokenStorage.deleteDeviceToken();
      await _tokenStorage.deleteDeviceTokenRegisteredAt();
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
        alert: false,
        badge: false,
        sound: false,
      );
    } catch (_) {
      // Ignore permission errors; app can still run without notifications.
    }
  }

  Future<void> _initLocalNotifications() async {
    if (_localNotificationReady) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    try {
      await _localNotifications.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationTap,
      );

      final androidImpl = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImpl?.createNotificationChannel(_offersChannel);
      _localNotificationReady = true;
    } on MissingPluginException {
      // App can continue without foreground local notifications.
      _localNotificationReady = false;
      _log(
        'Local notifications plugin not registered. Run a full restart/rebuild.',
      );
    } catch (e) {
      _localNotificationReady = false;
      _log('Local notifications init failed: $e');
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload?.trim();
    if (payload == null || payload.isEmpty) return;
    final target = _decodeNavigationPayload(payload);
    final rideRequestId = target?['rideRequestId'];
    if (rideRequestId != null && rideRequestId.isNotEmpty) {
      _rideOfferController.add(rideRequestId);
    }
    if (target != null) {
      unawaited(_queueNotificationNavigation(target));
      return;
    }
    _rideOfferController.add(payload);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('FCM foreground message: ${message.messageId}');
    }
    final target = _extractNavigationTarget(message.data);
    final rideRequestId = target?['rideRequestId'];
    if (rideRequestId != null && rideRequestId.isNotEmpty) {
      _rideOfferController.add(rideRequestId);
    }
    await _showForegroundNotification(message, navigationTarget: target);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final target = _extractNavigationTarget(message.data);
    if (target == null) return;
    final rideRequestId = target['rideRequestId'];
    if (rideRequestId != null && rideRequestId.isNotEmpty) {
      _rideOfferController.add(rideRequestId);
    }
    unawaited(_queueNotificationNavigation(target));
  }

  Future<void> _showForegroundNotification(
    RemoteMessage message, {
    Map<String, String>? navigationTarget,
  }) async {
    if (!_localNotificationReady) return;
    final title = message.notification?.title?.trim();
    final body = message.notification?.body?.trim();
    final rideRequestId = navigationTarget?['rideRequestId'];

    final hasVisualContent =
        (title != null && title.isNotEmpty) ||
        (body != null && body.isNotEmpty);
    if (!hasVisualContent && (rideRequestId == null || rideRequestId.isEmpty)) {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      _offersChannel.id,
      _offersChannel.name,
      channelDescription: _offersChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ride_offer',
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final resolvedTitle = title ?? 'New ride offer';
    final resolvedBody = body ?? 'Tap to review and respond.';

    try {
      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: resolvedTitle,
        body: resolvedBody,
        notificationDetails: NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: navigationTarget == null
            ? rideRequestId
            : jsonEncode(navigationTarget),
      );
    } on MissingPluginException {
      _localNotificationReady = false;
      _log(
        'Local notifications plugin missing at runtime. Disable foreground notification fallback.',
      );
    } catch (e) {
      _log('Failed to show foreground local notification: $e');
    }
  }

  Map<String, String>? _extractNavigationTarget(Map<String, dynamic> data) {
    if (data.isEmpty) return null;

    final kind = _firstNonEmpty(data, const [
      'kind',
      'notificationKind',
      'notification_kind',
      'event',
      'type',
    ]);
    final normalizedKind = kind?.trim().toLowerCase() ?? '';
    if (normalizedKind.isEmpty) return null;

    if (_rideRequestKinds.contains(normalizedKind)) {
      final rideRequestId = _firstNonEmpty(data, const [
        'rideRequestId',
        'ride_request_id',
        'requestId',
        'request_id',
      ]);
      if (rideRequestId == null || rideRequestId.isEmpty) return null;
      return {'kind': normalizedKind, 'rideRequestId': rideRequestId};
    }

    if (_rideCreatedKinds.contains(normalizedKind)) {
      final rideId = _firstNonEmpty(data, const ['rideId', 'ride_id']);
      if (rideId == null || rideId.isEmpty) return null;
      return {'kind': normalizedKind, 'rideId': rideId};
    }

    return null;
  }

  Map<String, String>? _decodeNavigationPayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        return decoded.map(
          (key, value) =>
              MapEntry(key.toString(), value?.toString().trim() ?? ''),
        );
      }
    } catch (_) {
      if (payload.trim().isNotEmpty) {
        return {
          'kind': 'ride_request_created_nearby',
          'rideRequestId': payload.trim(),
        };
      }
    }
    return null;
  }

  Future<void> _queueNotificationNavigation(Map<String, String> target) async {
    _pendingNavigationTarget = target;
    await flushPendingNavigation();
  }

  Future<void> flushPendingNavigation() async {
    if (_navigationInFlight) return;
    final target = _pendingNavigationTarget;
    if (target == null) return;
    if (!await _canNavigateNow()) return;

    _navigationInFlight = true;
    _pendingNavigationTarget = null;
    try {
      await _navigateToTarget(target);
    } catch (e) {
      _pendingNavigationTarget = target;
      _log('Notification navigation failed: $e');
    } finally {
      _navigationInFlight = false;
    }
  }

  Future<bool> _canNavigateNow() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      if (Get.key.currentState != null && Get.currentRoute != AppRoutes.gate) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return false;
  }

  Future<void> _navigateToTarget(Map<String, String> target) async {
    final kind = (target['kind'] ?? '').trim().toLowerCase();
    switch (kind) {
      case 'ride_request_created':
      case 'ride_request_created_nearby':
        final rideRequestId = (target['rideRequestId'] ?? '').trim();
        if (rideRequestId.isEmpty) return;
        await Get.toNamed(
          DriverRoutes.rideRequests,
          arguments: {
            'rideRequestId': rideRequestId,
            'autoOpenOfferSheet': true,
          },
        );
        return;
      case 'ride_created':
        final rideId = (target['rideId'] ?? '').trim();
        if (rideId.isEmpty) return;
        await Get.toNamed(
          RidesRoutes.search,
          arguments: {'focusRideId': rideId, 'rideId': rideId},
        );
        return;
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

    try {
      await _registerToken(token.trim());
    } catch (_) {
      _log('FCM token refresh registration failed; scheduling retry.');
      _scheduleRetry();
    }
  }

  Future<void> _registerToken(String token) async {
    if (_registering) return;
    _registering = true;
    try {
      final api = await _getApi();
      await api.registerToken(token: token, platform: _platform());
      await _tokenStorage.saveDeviceToken(token);
      await _tokenStorage.saveDeviceTokenRegisteredAt(DateTime.now().toUtc());
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
    await _tokenStorage.deleteDeviceTokenRegisteredAt();
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

  bool _isRegistrationStale(DateTime? registeredAt) {
    if (registeredAt == null) return true;
    final elapsed = DateTime.now().toUtc().difference(registeredAt);
    if (elapsed.isNegative) return true;
    return elapsed >= _tokenRefreshInterval;
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (_retryAttempts >= _maxRetryAttempts) {
      _log('FCM token missing; retry limit reached.');
      return;
    }
    _retryAttempts += 1;
    _log(
      'FCM token missing; retry $_retryAttempts/$_maxRetryAttempts scheduled.',
    );
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

String? _firstNonEmpty(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return null;
}
