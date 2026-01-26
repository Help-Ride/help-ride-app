import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../services/token_storage.dart';

class PushTokenOverlay extends StatefulWidget {
  const PushTokenOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<PushTokenOverlay> createState() => _PushTokenOverlayState();
}

class _PushTokenOverlayState extends State<PushTokenOverlay> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final TokenStorage _storage = TokenStorage();

  Timer? _timer;
  AuthorizationStatus? _authStatus;
  String? _apnsToken;
  String? _fcmToken;
  String? _cachedToken;
  String? _registeredToken;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      final apnsToken = Platform.isIOS ? await _safeGetApnsToken() : null;
      final fcmToken = await _safeGetFcmToken();
      final cached = await _storage.getCachedDeviceToken();
      final registered = await _storage.getDeviceToken();

      if (!mounted) return;
      setState(() {
        _authStatus = settings.authorizationStatus;
        _apnsToken = apnsToken;
        _fcmToken = fcmToken;
        _cachedToken = cached;
        _registeredToken = registered;
      });
    } catch (_) {
      // Keep overlay resilient; ignore errors.
    }
  }

  Future<String?> _safeGetFcmToken() async {
    try {
      return await _messaging.getToken();
    } on FirebaseException catch (e) {
      if (e.code == 'apns-token-not-set') return null;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _safeGetApnsToken() async {
    try {
      return await _messaging.getAPNSToken();
    } on FirebaseException catch (e) {
      if (e.code == 'apns-token-not-set') return null;
      return null;
    } catch (_) {
      return null;
    }
  }

  String _mask(String? token) {
    if (token == null || token.trim().isEmpty) return '—';
    final t = token.trim();
    if (t.length <= 8) return t;
    return '${t.substring(0, 4)}…${t.substring(t.length - 4)} (${t.length})';
  }

  String _statusLabel(AuthorizationStatus? status) {
    if (status == null) return 'unknown';
    return status.name;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 12,
          bottom: 12,
          child: SafeArea(
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Push Debug',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text('Permission: ${_statusLabel(_authStatus)}'),
                    Text('APNs: ${_mask(_apnsToken)}'),
                    Text('FCM: ${_mask(_fcmToken)}'),
                    Text('Cached: ${_mask(_cachedToken)}'),
                    Text('Registered: ${_mask(_registeredToken)}'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
