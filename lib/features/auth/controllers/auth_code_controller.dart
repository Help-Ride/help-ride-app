import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/auth/services/auth_analytics.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'package:help_ride/shared/services/api_exception.dart';
import 'package:help_ride/shared/services/api_client.dart';
import 'package:help_ride/shared/services/token_storage.dart';
import 'package:help_ride/shared/utils/input_validators.dart';
import 'package:help_ride/shared/utils/phone_number_utils.dart';
import '../routes/auth_routes.dart';
import '../services/auth_api.dart';

class AuthCodeController extends GetxController {
  final otp = ''.obs;
  final isSending = false.obs;
  final isVerifying = false.obs;
  final error = RxnString();
  final message = RxnString();
  final resendRemainingSeconds = 0.obs;

  final otpTextController = TextEditingController();

  late final AuthApi _authApi;
  late final TokenStorage _tokenStorage;

  String _deviceId = '';
  String _channel = 'phone';
  String _identifier = '';
  Timer? _resendTimer;

  String get channel => _channel;
  String get identifier => _identifier;
  bool get isPhoneChannel => _channel == 'phone';
  bool get canResend => resendRemainingSeconds.value == 0 && !isSending.value;
  bool get canVerify =>
      otpError == null && otp.value.trim().length == 6 && !isVerifying.value;
  String? get otpError => InputValidators.otpCode(otp.value);

  String get title => 'Enter the code';

  String get subtitle {
    if (isPhoneChannel) {
      final ending = PhoneNumberUtils.endingDigits(_identifier);
      if (ending.isEmpty) {
        return 'Enter the 6-digit code we sent by SMS.';
      }
      return 'Sent to the number ending in $ending.';
    }
    return 'Enter the 6-digit code from your email.';
  }

  String get wrongDestinationLabel =>
      isPhoneChannel ? 'Wrong number?' : 'Use another email';

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    final apiClient = await ApiClient.create();
    _authApi = AuthApi(apiClient);
    _tokenStorage = TokenStorage();
    _deviceId = await _tokenStorage.getOrCreateAuthDeviceId();

    final args = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments)
        : const <String, dynamic>{};
    _channel = args['channel']?.toString() == 'email' ? 'email' : 'phone';
    _identifier = args['identifier']?.toString().trim() ?? '';
    final resendDelay =
        int.tryParse('${args['resendAvailableInSeconds'] ?? 30}') ?? 30;
    AuthAnalytics.track('auth_code_viewed', {'channel': _channel});
    _startResendTimer(resendDelay);
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

    if (trimmed.length == 6 && !isVerifying.value) {
      unawaited(verifyOtp());
    }
  }

  Future<void> resendCode() async {
    if (!canResend) return;
    isSending.value = true;
    error.value = null;
    message.value = null;

    try {
      final result = isPhoneChannel
          ? await _authApi.sendContinuePhoneOtp(
              phone: _identifier,
              deviceId: _deviceId,
            )
          : await _authApi.sendContinueEmailOtp(
              email: _identifier,
              deviceId: _deviceId,
            );
      AuthAnalytics.track('auth_resend_requested', {'channel': _channel});
      message.value = result.message ?? 'Code sent.';
      _startResendTimer(result.resendAvailableInSeconds);
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      isSending.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (!canVerify) {
      error.value = otpError ?? 'Enter the 6-digit code to continue.';
      return;
    }

    isVerifying.value = true;
    error.value = null;
    message.value = null;

    try {
      final result = isPhoneChannel
          ? await _authApi.verifyContinuePhoneOtp(
              phone: _identifier,
              otp: otp.value.trim(),
              deviceId: _deviceId,
            )
          : await _authApi.verifyContinueEmailOtp(
              email: _identifier,
              otp: otp.value.trim(),
              deviceId: _deviceId,
            );

      final tokens = result.tokens;
      if (tokens != null) {
        await _persistTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          provider: isPhoneChannel ? 'phone' : 'email',
        );

        AuthAnalytics.track('auth_otp_verified', {'channel': _channel});
        AuthAnalytics.track('auth_existing_user_signed_in', {
          'channel': _channel,
        });

        final session = Get.find<SessionController>();
        await session.bootstrap();
        await session.openVerifiedAppDestination();
        return;
      }

      if (result.onboardingToken != null) {
        Get.offNamed(
          AuthRoutes.register,
          arguments: {
            'onboardingToken': result.onboardingToken,
            'channel': _channel,
            if (isPhoneChannel) 'phone': _identifier,
            if (!isPhoneChannel) 'email': _identifier,
            'hint': isPhoneChannel
                ? 'Phone verified. Add a few details to finish.'
                : 'Email verified. Add a few details to finish.',
          },
        );
        return;
      }

      throw Exception('Invalid verification response.');
    } catch (e) {
      AuthAnalytics.track('auth_otp_verification_failed', {
        'channel': _channel,
      });
      error.value = _prettyError(e);
    } finally {
      isVerifying.value = false;
    }
  }

  void wrongDestination() {
    Get.offNamed(
      AuthRoutes.login,
      arguments: {
        if (isPhoneChannel) 'phone': _identifier,
        if (!isPhoneChannel) 'email': _identifier,
      },
    );
  }

  Future<void> _persistTokens({
    required String accessToken,
    String? refreshToken,
    required String provider,
  }) async {
    await _tokenStorage.saveAccessToken(accessToken.trim());
    await _tokenStorage.saveAuthProvider(provider);
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      await _tokenStorage.saveRefreshToken(refreshToken.trim());
    } else {
      await _tokenStorage.deleteRefreshToken();
    }
  }

  void _startResendTimer(int seconds) {
    _resendTimer?.cancel();
    resendRemainingSeconds.value = seconds < 0 ? 0 : seconds;
    if (resendRemainingSeconds.value == 0) return;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = resendRemainingSeconds.value - 1;
      if (next <= 0) {
        resendRemainingSeconds.value = 0;
        timer.cancel();
      } else {
        resendRemainingSeconds.value = next;
      }
    });
  }

  String _prettyError(Object error) {
    if (error is DioException && error.error is ApiException) {
      return (error.error as ApiException).message;
    }
    if (error is DioException) {
      return 'Network error. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    otpTextController.dispose();
    super.onClose();
  }
}
