import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/auth/models/dial_code_option.dart';
import 'package:help_ride/features/auth/services/auth_analytics.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'package:help_ride/shared/services/api_exception.dart';
import 'package:help_ride/shared/services/api_client.dart';
import 'package:help_ride/shared/services/location_sync_service.dart';
import 'package:help_ride/shared/services/token_storage.dart';
import 'package:help_ride/shared/utils/input_validators.dart';
import 'package:help_ride/shared/utils/phone_number_utils.dart';
import '../routes/auth_routes.dart';
import '../services/apple_oauth_service.dart';
import '../services/auth_api.dart';
import '../services/google_oauth_service.dart';
import '../services/oauth_api.dart';

class AuthController extends GetxController {
  final phone = ''.obs;
  final email = ''.obs;
  final selectedDialCode = authDialCodeOptions.first.dialCode.obs;

  final firstName = ''.obs;
  final lastName = ''.obs;
  final onboardingEmail = ''.obs;
  final onboardingPhone = ''.obs;
  final onboardingHint = RxnString();

  final phoneTextController = TextEditingController();
  final emailTextController = TextEditingController();
  final firstNameTextController = TextEditingController();
  final lastNameTextController = TextEditingController();
  final onboardingEmailTextController = TextEditingController();
  final onboardingPhoneTextController = TextEditingController();

  final isReady = false.obs;
  final isSendingPhoneOtp = false.obs;
  final isSendingEmailOtp = false.obs;
  final isCompletingOnboarding = false.obs;
  final googleOauthLoading = false.obs;
  final appleOauthLoading = false.obs;

  final entryError = RxnString();
  final entryMessage = RxnString();
  final onboardingError = RxnString();
  final onboardingMessage = RxnString();

  late final TokenStorage _tokenStorage;
  late final AuthApi _authApi;
  late final OAuthApi _oauthApi;
  late final GoogleOAuthService _googleOAuth;
  late final AppleOAuthService _appleOAuth;

  String _deviceId = '';
  String? _entryArgsSignature;
  String? _onboardingArgsSignature;
  String? _onboardingToken;
  String _verifiedChannel = '';
  String? _verifiedPhone;
  String? _verifiedEmail;

  List<DialCodeOption> get dialCodeOptions => authDialCodeOptions;

  DialCodeOption get activeDialCodeOption {
    for (final option in authDialCodeOptions) {
      if (option.dialCode == selectedDialCode.value) {
        return option;
      }
    }
    return authDialCodeOptions.first;
  }

  bool get isOauthBusy => googleOauthLoading.value || appleOauthLoading.value;

  bool get canContinueWithPhone =>
      isReady.value &&
      !isSendingPhoneOtp.value &&
      !isOauthBusy &&
      entryPhoneError == null;

  bool get canContinueWithEmail =>
      isReady.value &&
      !isSendingEmailOtp.value &&
      !isOauthBusy &&
      entryEmailError == null;

  bool get canStartGoogleOauth =>
      isReady.value &&
      !isSendingPhoneOtp.value &&
      !isSendingEmailOtp.value &&
      !isOauthBusy;

  bool get canStartAppleOauth => canStartGoogleOauth;

  bool get shouldShowOnboardingEmailField => _verifiedChannel != 'email';
  bool get shouldShowOnboardingPhoneField => _verifiedChannel != 'phone';

  bool get canCompleteOnboarding =>
      isReady.value &&
      !isCompletingOnboarding.value &&
      firstNameError == null &&
      lastNameError == null &&
      onboardingEmailError == null &&
      onboardingPhoneError == null &&
      (_onboardingToken?.isNotEmpty ?? false);

  String? get entryPhoneError {
    if (phone.value.trim().isEmpty) {
      return 'Enter your phone number.';
    }
    return normalizedEntryPhone == null ? 'Enter a valid phone number.' : null;
  }

  String? get entryEmailError {
    if (email.value.trim().isEmpty) {
      return 'Enter your email address.';
    }
    return InputValidators.email(email.value);
  }

  String? get firstNameError =>
      _requiredNamePart(firstName.value, fieldLabel: 'First name');

  String? get lastNameError =>
      _requiredNamePart(lastName.value, fieldLabel: 'Last name');

  String? get onboardingEmailError {
    if (!shouldShowOnboardingEmailField ||
        onboardingEmail.value.trim().isEmpty) {
      return null;
    }
    return InputValidators.email(onboardingEmail.value);
  }

  String? get onboardingPhoneError {
    if (!shouldShowOnboardingPhoneField ||
        onboardingPhone.value.trim().isEmpty) {
      return null;
    }
    return normalizedOnboardingPhone == null
        ? 'Enter a valid mobile number.'
        : null;
  }

  String? get normalizedEntryPhone => _normalizePhoneInput(phone.value);

  String? get normalizedOnboardingPhone =>
      _normalizePhoneInput(onboardingPhone.value);

  String? get verifiedPhone => _verifiedPhone;
  String? get verifiedEmail => _verifiedEmail;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    _tokenStorage = TokenStorage();
    final apiClient = await ApiClient.create();
    _authApi = AuthApi(apiClient);
    _oauthApi = OAuthApi(apiClient);
    _googleOAuth = GoogleOAuthService();
    _appleOAuth = AppleOAuthService();
    _deviceId = await _tokenStorage.getOrCreateAuthDeviceId();
    isReady.value = true;
  }

  void prepareEntryFromRouteArgs() {
    final args = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments)
        : const <String, dynamic>{};
    final signature =
        '${args['phone'] ?? ''}|${args['email'] ?? ''}|${args['dialCode'] ?? ''}';
    if (_entryArgsSignature == signature) return;
    _entryArgsSignature = signature;
    AuthAnalytics.track('auth_entry_viewed');

    final phoneArg = args['phone']?.toString().trim() ?? '';
    _setField(
      phone,
      phoneTextController,
      _displayPhoneInput(phoneArg),
      clearEntryFeedback: false,
    );

    final emailArg = args['email']?.toString().trim() ?? '';
    _setField(email, emailTextController, emailArg, clearEntryFeedback: false);
  }

  void prepareOnboardingFromRouteArgs() {
    final args = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments)
        : const <String, dynamic>{};
    final signature =
        '${args['onboardingToken'] ?? ''}|${args['channel'] ?? ''}|${args['hint'] ?? ''}';
    if (_onboardingArgsSignature == signature) return;
    _onboardingArgsSignature = signature;
    AuthAnalytics.track('auth_onboarding_viewed');

    _setField(
      firstName,
      firstNameTextController,
      '',
      clearEntryFeedback: false,
      clearOnboardingFeedback: false,
    );
    _setField(
      lastName,
      lastNameTextController,
      '',
      clearEntryFeedback: false,
      clearOnboardingFeedback: false,
    );
    _setField(
      onboardingEmail,
      onboardingEmailTextController,
      '',
      clearEntryFeedback: false,
      clearOnboardingFeedback: false,
    );
    _setField(
      onboardingPhone,
      onboardingPhoneTextController,
      '',
      clearEntryFeedback: false,
      clearOnboardingFeedback: false,
    );

    _onboardingToken = args['onboardingToken']?.toString();
    _verifiedChannel = args['channel']?.toString() ?? '';
    onboardingHint.value = args['hint']?.toString();

    final verifiedPhoneArg = args['phone']?.toString().trim();
    final verifiedEmailArg = args['email']?.toString().trim();
    _verifiedPhone = verifiedPhoneArg?.isEmpty ?? true
        ? null
        : verifiedPhoneArg;
    _verifiedEmail = verifiedEmailArg?.isEmpty ?? true
        ? null
        : verifiedEmailArg;

    if (_verifiedChannel == 'phone' && _verifiedPhone != null) {
      _setField(
        onboardingPhone,
        onboardingPhoneTextController,
        '',
        clearOnboardingFeedback: false,
      );
    }

    if (_verifiedChannel == 'email' && _verifiedEmail != null) {
      _setField(
        onboardingEmail,
        onboardingEmailTextController,
        '',
        clearOnboardingFeedback: false,
      );
    }

    if (args['suggestedEmail'] is String &&
        '${args['suggestedEmail']}'.trim().isNotEmpty) {
      _setField(
        onboardingEmail,
        onboardingEmailTextController,
        '${args['suggestedEmail']}'.trim(),
        clearOnboardingFeedback: false,
      );
    }

    if (args['suggestedPhone'] is String &&
        '${args['suggestedPhone']}'.trim().isNotEmpty) {
      _setField(
        onboardingPhone,
        onboardingPhoneTextController,
        _displayPhoneInput('${args['suggestedPhone']}'.trim()),
        clearOnboardingFeedback: false,
      );
    }
  }

  void setPhone(String value) {
    _setField(phone, phoneTextController, value);
  }

  void setEmail(String value) {
    _setField(email, emailTextController, value);
  }

  void setFirstName(String value) {
    _setField(
      firstName,
      firstNameTextController,
      value,
      clearEntryFeedback: false,
      clearOnboardingFeedback: true,
    );
  }

  void setLastName(String value) {
    _setField(
      lastName,
      lastNameTextController,
      value,
      clearEntryFeedback: false,
      clearOnboardingFeedback: true,
    );
  }

  void setOnboardingEmail(String value) {
    _setField(
      onboardingEmail,
      onboardingEmailTextController,
      value,
      clearEntryFeedback: false,
      clearOnboardingFeedback: true,
    );
  }

  void setOnboardingPhone(String value) {
    _setField(
      onboardingPhone,
      onboardingPhoneTextController,
      value,
      clearEntryFeedback: false,
      clearOnboardingFeedback: true,
    );
  }

  void setDialCode(DialCodeOption option) {
    if (selectedDialCode.value == option.dialCode) return;
    selectedDialCode.value = option.dialCode;
    clearEntryFeedback();
    clearOnboardingFeedback();
  }

  Future<bool> sendPhoneContinueOtp() async {
    if (!canContinueWithPhone || normalizedEntryPhone == null) {
      entryError.value = entryPhoneError ?? 'Enter your phone number.';
      return false;
    }

    isSendingPhoneOtp.value = true;
    clearEntryFeedback();

    try {
      AuthAnalytics.track('auth_phone_entered', {'channel': 'phone'});
      final result = await _authApi.sendContinuePhoneOtp(
        phone: normalizedEntryPhone!,
        deviceId: _deviceId,
      );
      AuthAnalytics.track('auth_otp_sent', {'channel': 'phone'});
      entryMessage.value = result.message ?? 'Code sent.';
      Get.toNamed(
        AuthRoutes.code,
        arguments: {
          'channel': 'phone',
          'identifier': normalizedEntryPhone,
          'resendAvailableInSeconds': result.resendAvailableInSeconds,
        },
      );
      return true;
    } catch (e) {
      AuthAnalytics.track('auth_otp_send_failed', {'channel': 'phone'});
      entryError.value = _prettyError(e);
      return false;
    } finally {
      isSendingPhoneOtp.value = false;
    }
  }

  Future<bool> sendEmailContinueOtp() async {
    if (!canContinueWithEmail) {
      entryError.value = entryEmailError ?? 'Enter your email address.';
      return false;
    }

    isSendingEmailOtp.value = true;
    clearEntryFeedback();

    try {
      AuthAnalytics.track('auth_email_fallback_tapped');
      final result = await _authApi.sendContinueEmailOtp(
        email: email.value.trim(),
        deviceId: _deviceId,
      );
      AuthAnalytics.track('auth_otp_sent', {'channel': 'email'});
      entryMessage.value = result.message ?? 'Code sent.';
      Get.toNamed(
        AuthRoutes.code,
        arguments: {
          'channel': 'email',
          'identifier': email.value.trim(),
          'resendAvailableInSeconds': result.resendAvailableInSeconds,
        },
      );
      return true;
    } catch (e) {
      AuthAnalytics.track('auth_email_fallback_failed');
      entryError.value = _prettyError(e);
      return false;
    } finally {
      isSendingEmailOtp.value = false;
    }
  }

  Future<void> completeOnboarding() async {
    if (!canCompleteOnboarding || _onboardingToken == null) {
      onboardingError.value =
          firstNameError ??
          lastNameError ??
          onboardingEmailError ??
          onboardingPhoneError ??
          'Complete the required fields to continue.';
      return;
    }

    isCompletingOnboarding.value = true;
    clearOnboardingFeedback();

    try {
      final result = await _authApi.completeOnboarding(
        onboardingToken: _onboardingToken!,
        firstName: firstName.value.trim(),
        lastName: lastName.value.trim(),
        deviceId: _deviceId,
        email: shouldShowOnboardingEmailField
            ? onboardingEmail.value.trim()
            : null,
        phone: shouldShowOnboardingPhoneField
            ? normalizedOnboardingPhone
            : null,
      );

      final tokens = result.tokens;
      if (tokens == null) {
        throw Exception('Missing session tokens in onboarding response.');
      }

      await _persistTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        provider: _verifiedChannel == 'phone' ? 'phone' : 'email',
      );

      AuthAnalytics.track('auth_new_user_created', {
        'channel': _verifiedChannel,
      });

      final session = Get.find<SessionController>();
      await session.bootstrap();
      await session.openVerifiedAppDestination();
    } catch (e) {
      onboardingError.value = _prettyError(e);
    } finally {
      isCompletingOnboarding.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    if (!canStartGoogleOauth) return;

    googleOauthLoading.value = true;
    clearEntryFeedback();
    AuthAnalytics.track('auth_google_tapped');

    try {
      final acc = await _googleOAuth.signIn();
      if (acc == null) {
        AuthAnalytics.track('auth_google_failed', {'reason': 'cancelled'});
        return;
      }

      final authLocation = await LocationSyncService.instance
          .captureCurrentLocation(requestPermission: false);
      final oauthName = acc.name.trim().isEmpty ? 'User' : acc.name.trim();
      final tokens = await _oauthApi.oauthLogin(
        provider: 'google',
        providerUserId: acc.id,
        email: acc.email,
        name: oauthName,
        avatarUrl: acc.avatarUrl,
        location: authLocation,
      );

      await _persistTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        provider: 'google',
      );
      AuthAnalytics.track('auth_google_success');
      await _finishAuthenticatedFlow();
    } catch (e) {
      AuthAnalytics.track('auth_google_failed');
      entryError.value = _prettyError(e);
    } finally {
      googleOauthLoading.value = false;
    }
  }

  Future<void> loginWithApple() async {
    if (!canStartAppleOauth) return;

    appleOauthLoading.value = true;
    clearEntryFeedback();
    AuthAnalytics.track('auth_apple_tapped');

    try {
      final credential = await _appleOAuth.signIn();
      if (credential == null) {
        AuthAnalytics.track('auth_apple_failed', {'reason': 'cancelled'});
        return;
      }

      final authLocation = await LocationSyncService.instance
          .captureCurrentLocation(requestPermission: false);
      final oauthName = (credential.fullName ?? '').trim().isEmpty
          ? 'Apple User'
          : credential.fullName!.trim();
      final tokens = await _oauthApi.oauthLogin(
        provider: 'apple',
        providerUserId: credential.userIdentifier,
        email: credential.email,
        name: oauthName,
        identityToken: credential.identityToken,
        location: authLocation,
      );

      await _persistTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        provider: 'apple',
      );
      AuthAnalytics.track('auth_apple_success');
      await _finishAuthenticatedFlow();
    } catch (e) {
      AuthAnalytics.track('auth_apple_failed');
      entryError.value = _prettyError(e);
    } finally {
      appleOauthLoading.value = false;
    }
  }

  void openLogin({Map<String, dynamic>? arguments, bool replace = false}) {
    clearEntryFeedback();
    clearOnboardingFeedback();
    if (replace) {
      Get.offAllNamed(AuthRoutes.login, arguments: arguments);
      return;
    }
    Get.offNamed(AuthRoutes.login, arguments: arguments);
  }

  Future<void> _persistTokens({
    required String accessToken,
    String? refreshToken,
    required String provider,
  }) async {
    await _tokenStorage.saveAccessToken(accessToken.trim());
    await _tokenStorage.saveAuthProvider(provider.trim());
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      await _tokenStorage.saveRefreshToken(refreshToken.trim());
    } else {
      await _tokenStorage.deleteRefreshToken();
    }
  }

  Future<void> _finishAuthenticatedFlow() async {
    final session = Get.find<SessionController>();
    await session.bootstrap();
    await session.openVerifiedAppDestination();
  }

  void clearEntryFeedback() {
    entryError.value = null;
    entryMessage.value = null;
  }

  void clearOnboardingFeedback() {
    onboardingError.value = null;
    onboardingMessage.value = null;
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

  String? _requiredNamePart(String value, {required String fieldLabel}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '$fieldLabel is required.';
    }
    if (trimmed.length < 2) {
      return '$fieldLabel must be at least 2 characters.';
    }
    return null;
  }

  String? _normalizePhoneInput(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return null;
    return PhoneNumberUtils.normalizeToE164(trimmed);
  }

  String _displayPhoneInput(String value) {
    if (value.trim().isEmpty) return '';
    return PhoneNumberUtils.formatForDisplay(value);
  }

  void _setField(
    RxString target,
    TextEditingController controller,
    String value, {
    bool clearEntryFeedback = true,
    bool clearOnboardingFeedback = false,
  }) {
    target.value = value;
    if (controller.text != value) {
      controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    if (clearEntryFeedback) {
      this.clearEntryFeedback();
    }
    if (clearOnboardingFeedback) {
      this.clearOnboardingFeedback();
    }
  }

  @override
  void onClose() {
    phoneTextController.dispose();
    emailTextController.dispose();
    firstNameTextController.dispose();
    lastNameTextController.dispose();
    onboardingEmailTextController.dispose();
    onboardingPhoneTextController.dispose();
    super.onClose();
  }
}
