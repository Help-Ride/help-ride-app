import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'package:help_ride/shared/services/api_exception.dart';
import 'package:help_ride/shared/services/api_client.dart';
import 'package:help_ride/shared/services/token_storage.dart';
import 'package:help_ride/shared/utils/input_validators.dart';
import 'package:help_ride/shared/utils/phone_number_utils.dart';
import '../../profile/services/profile_api.dart';
import '../routes/auth_routes.dart';
import '../services/auth_api.dart';

class PhoneVerificationController extends GetxController {
  final otp = ''.obs;
  final phoneInput = ''.obs;
  final phoneTextController = TextEditingController();
  final otpTextController = TextEditingController();
  final isSending = false.obs;
  final isSavingPhone = false.obs;
  final isVerifying = false.obs;
  final error = RxnString();
  final message = RxnString();

  final _phone = ''.obs;
  final _email = ''.obs;
  final _provider = ''.obs;
  final _allowBackToLogin = true.obs;
  var _autoSent = false;
  bool _shouldAutoSend = true;

  late final TokenStorage _tokenStorage;
  late final AuthApi _authApi;
  late final ProfileApi _profileApi;
  late final SessionController _session;

  String get phone => _phone.value;
  String get maskedPhone => PhoneNumberUtils.maskForDisplay(_phone.value);
  String get phoneEndingDigits => PhoneNumberUtils.endingDigits(_phone.value);
  String get email => _email.value;
  String get provider => _provider.value;
  bool get hasPhone => _phone.value.trim().isNotEmpty;
  bool get allowBackToLogin => _allowBackToLogin.value;
  String? get otpError => InputValidators.otpCode(otp.value);
  String? get phoneError => InputValidators.phone(phoneInput.value);
  bool get canVerify => otpError == null && !isVerifying.value;
  bool get canSubmitPhone =>
      phoneError == null && !isSavingPhone.value && !isSending.value;

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
    final argPhone = args['phone']?.toString().trim() ?? '';
    _phone.value = argPhone.isNotEmpty
        ? argPhone
        : ((_session.user.value?.pendingPhone?.trim().isNotEmpty ?? false)
              ? _session.user.value!.pendingPhone!.trim()
              : (_session.user.value?.phone?.trim() ?? ''));
    _setField(
      phoneInput,
      phoneTextController,
      _phone.value,
      clearFeedback: false,
    );
    _email.value = (args['email']?.toString().trim() ?? '');
    _provider.value = (args['provider']?.toString().trim() ?? '');
    _allowBackToLogin.value = args['allowBackToLogin'] != false;
    _shouldAutoSend = args['autoSend'] != false;

    if (_provider.value.isEmpty) {
      final storedProvider = await _tokenStorage.getAuthProvider();
      _provider.value = storedProvider?.trim().isNotEmpty == true
          ? storedProvider!.trim()
          : _session.authProvider;
    }

    if (_phone.value.isNotEmpty && _shouldAutoSend) {
      _autoSendIfReady();
    }
  }

  @override
  void onReady() {
    super.onReady();
    if (_shouldAutoSend) {
      _autoSendIfReady();
    }
  }

  void _autoSendIfReady() {
    if (_autoSent || _phone.value.isEmpty) return;
    _autoSent = true;
    sendOtp();
  }

  void setOtp(String value) {
    _setField(otp, otpTextController, value);
  }

  void setPhone(String value) {
    _setField(phoneInput, phoneTextController, value);
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
      Get.offAllNamed(
        AuthRoutes.login,
        arguments: {
          if (_phone.value.isNotEmpty) 'phone': _phone.value,
          if (_email.value.isNotEmpty) 'email': _email.value,
        },
      );
      return;
    }

    await _session.logout();
    Get.offAllNamed(
      AuthRoutes.login,
      arguments: {
        if (_phone.value.isNotEmpty) 'phone': _phone.value,
        if (_email.value.isNotEmpty) 'email': _email.value,
      },
    );
  }

  Future<void> closeFlow() async {
    await goBack();
  }

  Future<void> savePhoneAndSendOtp() async {
    final validation = phoneError;
    if (validation != null) {
      error.value = validation;
      return;
    }

    final userId = _session.user.value?.id ?? '';
    if (userId.isEmpty) {
      error.value = 'Please sign in again to continue.';
      return;
    }

    final normalizedPhone = PhoneNumberUtils.normalizeToE164(phoneInput.value);
    if (normalizedPhone == null) {
      error.value = 'Enter a valid mobile number.';
      return;
    }

    isSavingPhone.value = true;
    error.value = null;
    message.value = null;

    try {
      final updatedUser = await _profileApi.updateUserProfile(
        userId,
        phone: normalizedPhone,
      );
      _phone.value = updatedUser.pendingPhone?.trim().isNotEmpty ?? false
          ? updatedUser.pendingPhone!.trim()
          : (updatedUser.phone?.trim() ?? normalizedPhone);
      _setField(
        phoneInput,
        phoneTextController,
        _phone.value,
        clearFeedback: false,
      );
      _setField(otp, otpTextController, '', clearFeedback: false);
      _email.value = updatedUser.email;
      await _session.bootstrap();
      await sendOtp();
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      isSavingPhone.value = false;
    }
  }

  Future<void> sendOtp() async {
    if (isSending.value || _phone.value.isEmpty) {
      if (_phone.value.isEmpty) {
        error.value = 'Enter your mobile number first.';
      }
      return;
    }
    isSending.value = true;
    error.value = null;
    message.value = null;

    try {
      await _authApi.sendVerifyPhoneOtp(phone: _phone.value);
      final ending = phoneEndingDigits;
      message.value = ending.isEmpty
          ? 'Code sent by SMS.'
          : 'Code sent to number ending in $ending.';
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
      final result = await _authApi.verifyPhoneOtp(
        phone: _phone.value,
        otp: otp.value.trim(),
      );

      final tokens = result?.tokens;
      if (tokens == null) {
        throw Exception('Missing access token in phone verification response');
      }

      await _tokenStorage.saveAccessToken(tokens.accessToken);
      await _tokenStorage.saveAuthProvider(
        provider.trim().isNotEmpty ? provider.trim() : 'email',
      );
      if (tokens.refreshToken != null) {
        await _tokenStorage.saveRefreshToken(tokens.refreshToken!);
      } else {
        await _tokenStorage.deleteRefreshToken();
      }

      final session = Get.find<SessionController>();
      await session.bootstrap();
      await session.openVerifiedAppDestination();
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
    phoneTextController.dispose();
    otpTextController.dispose();
    super.onClose();
  }
}
