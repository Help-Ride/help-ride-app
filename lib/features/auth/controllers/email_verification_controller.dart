import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/core/routes/app_routes.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'package:help_ride/shared/services/api_exception.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/services/token_storage.dart';
import '../../../shared/models/user.dart';
import '../../../shared/services/location_sync_service.dart';
import '../../../shared/services/push_notification_service.dart';
import '../../../shared/utils/input_validators.dart';
import '../routes/auth_routes.dart';
import '../services/auth_api.dart';

class EmailVerificationController extends GetxController {
  final otp = ''.obs;
  final isSending = false.obs;
  final isVerifying = false.obs;
  final error = RxnString();
  final message = RxnString();
  final otpTextController = TextEditingController();

  final _email = ''.obs;
  final _allowBackToLogin = true.obs;
  var _autoSent = false;

  late final TokenStorage _tokenStorage;
  late final AuthApi _authApi;
  late final SessionController _session;

  String get email => _email.value;
  bool get allowBackToLogin => _allowBackToLogin.value;
  String? get otpError => InputValidators.otpCode(otp.value);
  bool get canVerify => otpError == null && !isVerifying.value;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    _tokenStorage = TokenStorage();
    final apiClient = await ApiClient.create();
    _authApi = AuthApi(apiClient);
    _session = Get.find<SessionController>();

    final args = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments)
        : const <String, dynamic>{};
    final argEmail = args['email'];
    _allowBackToLogin.value = args['allowBackToLogin'] != false;
    _email.value = (argEmail?.toString().trim().isNotEmpty ?? false)
        ? argEmail.toString().trim()
        : (_session.user.value?.email ?? '');

    if (_email.value.isEmpty) {
      error.value = 'Missing email for verification.';
      return;
    }
    _autoSendIfReady();
  }

  @override
  void onReady() {
    super.onReady();
    _autoSendIfReady();
  }

  void _autoSendIfReady() {
    if (_autoSent || _email.value.isEmpty) return;
    _autoSent = true;
    sendOtp();
  }

  void setOtp(String value) {
    final trimmed = value.trim();
    otp.value = trimmed;
    if (otpTextController.text != trimmed) {
      otpTextController.value = TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
    }
    error.value = null;
  }

  Future<void> goBack() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final canPop = Get.key.currentState?.canPop() ?? false;
    final hasSession = _session.status.value == SessionStatus.authenticated;

    if (canPop && hasSession) {
      Get.back<void>();
      return;
    }

    if (allowBackToLogin) {
      Get.offAllNamed(AuthRoutes.login, arguments: {'email': _email.value});
      return;
    }

    await _session.logout();
    Get.offAllNamed(AuthRoutes.login, arguments: {'email': _email.value});
  }

  Future<void> closeFlow() async {
    await goBack();
  }

  Future<void> sendOtp() async {
    if (isSending.value || _email.value.isEmpty) return;
    isSending.value = true;
    error.value = null;
    message.value = null;

    try {
      await _authApi.sendVerifyEmailOtp(email: _email.value);
      message.value = 'Code sent to your email.';
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      isSending.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (!canVerify) {
      error.value = otpError ?? 'Please fix highlighted fields.';
      return;
    }

    isVerifying.value = true;
    error.value = null;
    message.value = null;

    try {
      final result = await _authApi.verifyEmailOtp(
        email: _email.value,
        otp: otp.value.trim(),
      );

      final tokens = result?.tokens;
      if (tokens != null) {
        await _tokenStorage.saveAccessToken(tokens.accessToken);
        await _tokenStorage.saveAuthProvider('email');
        if (tokens.refreshToken != null) {
          await _tokenStorage.saveRefreshToken(tokens.refreshToken!);
        } else {
          await _tokenStorage.deleteRefreshToken();
        }

        final session = Get.find<SessionController>();
        final userJson = result?.user;
        if (userJson != null) {
          if (!userJson.containsKey('emailVerified')) {
            userJson['emailVerified'] = true;
          }
          session.user.value = User.fromJson(userJson);
          session.status.value = SessionStatus.authenticated;
          try {
            await PushNotificationService.instance
                .registerDeviceTokenIfNeeded();
          } catch (_) {
            // Best-effort token registration.
          }
        } else {
          await session.bootstrap();
        }
        unawaited(
          LocationSyncService.instance.syncMyLocation(
            requestPermission: false,
            force: true,
          ),
        );
        Get.offAllNamed(AppRoutes.shell);
      } else {
        message.value = 'Email verified. Please sign in.';
        Get.offAllNamed(AuthRoutes.login);
      }
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      isVerifying.value = false;
    }
  }

  String _prettyError(Object e) {
    if (e is DioException && e.error is ApiException) {
      return (e.error as ApiException).message;
    }

    if (e is DioException) {
      return 'Network error. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  @override
  void onClose() {
    otpTextController.dispose();
    super.onClose();
  }
}
