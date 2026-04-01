import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'package:help_ride/shared/services/api_exception.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/services/token_storage.dart';
import '../../../shared/utils/input_validators.dart';
import '../../profile/services/profile_api.dart';
import '../routes/auth_routes.dart';
import '../services/auth_api.dart';

class EmailVerificationController extends GetxController {
  final otp = ''.obs;
  final emailInput = ''.obs;
  final emailTextController = TextEditingController();
  final isSending = false.obs;
  final isSavingEmail = false.obs;
  final isVerifying = false.obs;
  final error = RxnString();
  final message = RxnString();
  final otpTextController = TextEditingController();

  final _email = ''.obs;
  final _provider = ''.obs;
  final _allowBackToLogin = true.obs;
  var _autoSent = false;

  late final TokenStorage _tokenStorage;
  late final AuthApi _authApi;
  late final ProfileApi _profileApi;
  late final SessionController _session;

  String get email => _email.value;
  String get provider => _provider.value;
  bool get hasEmail => _email.value.trim().isNotEmpty;
  bool get allowBackToLogin => _allowBackToLogin.value;
  String? get otpError => InputValidators.otpCode(otp.value);
  String? get emailError {
    final trimmed = emailInput.value.trim();
    if (trimmed.isEmpty) {
      return 'Enter your email address.';
    }
    return InputValidators.email(trimmed);
  }

  bool get canVerify => otpError == null && !isVerifying.value;
  bool get canSubmitEmail =>
      emailError == null && !isSavingEmail.value && !isSending.value;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    _tokenStorage = TokenStorage();
    final apiClient = await ApiClient.create();
    _authApi = AuthApi(apiClient);
    _profileApi = ProfileApi(apiClient);
    _session = Get.find<SessionController>();

    final args = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments)
        : const <String, dynamic>{};
    final argEmail = args['email'];
    _allowBackToLogin.value = args['allowBackToLogin'] != false;
    _provider.value = args['provider']?.toString().trim() ?? '';
    _email.value = (argEmail?.toString().trim().isNotEmpty ?? false)
        ? argEmail.toString().trim()
        : ((_session.user.value?.pendingEmail?.trim().isNotEmpty ?? false)
              ? _session.user.value!.pendingEmail!.trim()
              : (_session.user.value?.email ?? ''));
    _setField(
      emailInput,
      emailTextController,
      _email.value,
      clearFeedback: false,
    );

    if (_provider.value.isEmpty) {
      final storedProvider = await _tokenStorage.getAuthProvider();
      _provider.value = storedProvider?.trim().isNotEmpty == true
          ? storedProvider!.trim()
          : _session.authProvider;
    }

    _autoSendIfReady();
  }

  @override
  void onReady() {
    super.onReady();
    _autoSendIfReady();
  }

  void _autoSendIfReady() {
    if (_autoSent || !hasEmail) return;
    _autoSent = true;
    unawaited(sendOtp());
  }

  void setEmail(String value) {
    _setField(emailInput, emailTextController, value);
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

    if (allowBackToLogin && canPop && hasSession) {
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

  Future<void> saveEmailAndSendOtp() async {
    final validation = emailError;
    if (validation != null) {
      error.value = validation;
      return;
    }

    final userId = _session.user.value?.id ?? '';
    if (userId.isEmpty) {
      error.value = 'Please sign in again to continue.';
      return;
    }

    isSavingEmail.value = true;
    error.value = null;
    message.value = null;

    try {
      final updatedUser = await _profileApi.updateUserProfile(
        userId,
        email: emailInput.value.trim(),
      );
      _email.value = updatedUser.pendingEmail?.trim().isNotEmpty ?? false
          ? updatedUser.pendingEmail!.trim()
          : updatedUser.email.trim();
      _setField(
        emailInput,
        emailTextController,
        _email.value,
        clearFeedback: false,
      );
      _setField(otp, otpTextController, '', clearFeedback: false);
      await _session.bootstrap();
      await sendOtp();
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      isSavingEmail.value = false;
    }
  }

  Future<void> sendOtp() async {
    if (isSending.value || !hasEmail) {
      if (!hasEmail) {
        error.value = 'Enter your email address first.';
      }
      return;
    }
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
        await _tokenStorage.saveAuthProvider(
          provider.trim().isNotEmpty ? provider.trim() : 'email',
        );
        if (tokens.refreshToken != null) {
          await _tokenStorage.saveRefreshToken(tokens.refreshToken!);
        } else {
          await _tokenStorage.deleteRefreshToken();
        }

        await _session.bootstrap();
        await _session.openVerifiedAppDestination();
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

  void _setField(
    RxString target,
    TextEditingController controller,
    String value, {
    bool clearFeedback = true,
  }) {
    target.value = value;
    if (controller.text != value) {
      controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    if (clearFeedback) {
      error.value = null;
      message.value = null;
    }
  }

  @override
  void onClose() {
    emailTextController.dispose();
    otpTextController.dispose();
    super.onClose();
  }
}
