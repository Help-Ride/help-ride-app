import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:help_ride/core/routes/app_routes.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'package:help_ride/shared/services/api_exception.dart';
import 'package:help_ride/shared/services/location_sync_service.dart';
import 'package:help_ride/shared/utils/input_validators.dart';
import 'package:help_ride/shared/utils/phone_number_utils.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/services/token_storage.dart';
import '../routes/auth_routes.dart';
import '../services/apple_oauth_service.dart';
import '../services/auth_api.dart';
import '../services/google_oauth_service.dart';
import '../services/oauth_api.dart';

enum AuthLoginMethod { password, otp }

class AuthController extends GetxController {
  final email = ''.obs;
  final password = ''.obs;
  final name = ''.obs;
  final phone = ''.obs;
  final otpIdentifier = ''.obs;
  final loginOtp = ''.obs;

  final loginMethod = AuthLoginMethod.password.obs;

  final isLoading = false.obs;
  final googleOauthLoading = false.obs;
  final appleOauthLoading = false.obs;
  final isSendingOtp = false.obs;
  final isVerifyingOtp = false.obs;
  final otpSent = false.obs;

  final error = RxnString();
  final message = RxnString();
  final isReady = false.obs;

  late final TokenStorage _tokenStorage;
  late final AuthApi _authApi;
  late final OAuthApi _oauthApi;
  late final GoogleOAuthService _googleOAuth;
  late final AppleOAuthService _appleOAuth;

  String? get emailError => InputValidators.email(email.value);
  String? get passwordError => InputValidators.password(password.value);
  String? get nameError => InputValidators.optionalName(name.value);
  String? get registerPhoneError => InputValidators.optionalPhone(phone.value);
  String? get otpIdentifierError =>
      InputValidators.emailOrPhone(otpIdentifier.value);
  String? get loginOtpError => InputValidators.otpCode(loginOtp.value);

  bool get isOtpLogin => loginMethod.value == AuthLoginMethod.otp;

  bool get isOtpPhoneInput =>
      otpIdentifierError == null && normalizedOtpPhone != null;
  bool get isOtpEmailInput =>
      otpIdentifierError == null &&
      otpIdentifier.value.trim().isNotEmpty &&
      normalizedOtpPhone == null;

  bool get canSubmit =>
      isReady.value &&
      emailError == null &&
      passwordError == null &&
      !isLoading.value &&
      !isOauthBusy;

  bool get canRegister =>
      isReady.value &&
      nameError == null &&
      emailError == null &&
      passwordError == null &&
      registerPhoneError == null &&
      !isLoading.value &&
      !isOauthBusy;

  bool get canSendLoginOtp {
    if (!isReady.value || isLoading.value || isOauthBusy) return false;
    if (isSendingOtp.value || isVerifyingOtp.value) return false;
    return otpIdentifierError == null;
  }

  bool get canVerifyLoginOtp {
    if (!otpSent.value || isVerifyingOtp.value || isSendingOtp.value) {
      return false;
    }
    return otpIdentifierError == null && loginOtpError == null;
  }

  String? get normalizedPhone => PhoneNumberUtils.normalizeToE164(phone.value);
  String? get normalizedOtpPhone =>
      PhoneNumberUtils.normalizeToE164(otpIdentifier.value);
  String get normalizedOtpEmail => otpIdentifier.value.trim();
  bool get isOauthBusy => googleOauthLoading.value || appleOauthLoading.value;
  bool get canStartGoogleOauth =>
      isReady.value &&
      !isLoading.value &&
      !isSendingOtp.value &&
      !isVerifyingOtp.value &&
      !isOauthBusy;
  bool get canStartAppleOauth => canStartGoogleOauth;

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
    isReady.value = true;
  }

  void setEmail(String value) {
    email.value = value;
    _clearFeedback();
  }

  void setPassword(String value) {
    password.value = value;
    _clearFeedback();
  }

  void setName(String value) {
    name.value = value;
    _clearFeedback();
  }

  void setPhone(String value) {
    phone.value = value;
    _clearFeedback();
  }

  void setOtpIdentifier(String value) {
    otpIdentifier.value = value;
    _clearFeedback();
    if (isOtpLogin) {
      _resetOtpState();
    }
  }

  void setLoginOtp(String value) {
    loginOtp.value = value;
    error.value = null;
    message.value = null;
  }

  void selectLoginMethod(AuthLoginMethod method) {
    if (loginMethod.value == method) return;
    loginMethod.value = method;
    _clearFeedback();
    _resetOtpState();
  }

  Future<void> loginWithEmail() async {
    if (!canSubmit) {
      error.value =
          emailError ?? passwordError ?? 'Please fix highlighted fields.';
      return;
    }

    isLoading.value = true;
    _clearFeedback();

    try {
      final authLocation = await LocationSyncService.instance
          .captureCurrentLocation(requestPermission: false);
      final result = await _authApi.loginWithEmail(
        email: email.value.trim(),
        password: password.value.trim(),
        location: authLocation,
      );

      await _persistTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      await _finishAuthenticatedFlow();
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendLoginOtp() async {
    if (!canSendLoginOtp) {
      error.value =
          otpIdentifierError ??
          'Please enter a valid email address or mobile number.';
      return;
    }

    isSendingOtp.value = true;
    _clearFeedback();

    try {
      if (isOtpPhoneInput) {
        final phoneNumber = normalizedOtpPhone!;
        await _authApi.sendVerifyPhoneOtp(phone: phoneNumber);
        message.value =
            'We texted a 6-digit sign-in code to ${PhoneNumberUtils.maskForDisplay(phoneNumber)}.';
      } else {
        await _authApi.sendVerifyEmailOtp(email: normalizedOtpEmail);
        message.value = 'We sent a 6-digit sign-in code to your email.';
      }
      otpSent.value = true;
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      isSendingOtp.value = false;
    }
  }

  Future<void> verifyLoginOtp() async {
    if (!canVerifyLoginOtp) {
      error.value =
          loginOtpError ?? 'Please enter the 6-digit verification code.';
      return;
    }

    isVerifyingOtp.value = true;
    _clearFeedback();

    try {
      final result = isOtpPhoneInput
          ? await _authApi.verifyPhoneOtp(
              phone: normalizedOtpPhone!,
              otp: loginOtp.value.trim(),
            )
          : await _authApi.verifyEmailOtp(
              email: normalizedOtpEmail,
              otp: loginOtp.value.trim(),
            );

      final tokens = result?.tokens;
      if (tokens == null) {
        throw Exception('Missing access token in OTP response');
      }

      await _persistTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      await _finishAuthenticatedFlow();
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      isVerifyingOtp.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    if (!canStartGoogleOauth) return;

    googleOauthLoading.value = true;
    _clearFeedback();

    try {
      final acc = await _googleOAuth.signIn();
      if (acc == null) return;

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
      await _finishAuthenticatedFlow();
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      googleOauthLoading.value = false;
    }
  }

  Future<void> loginWithApple() async {
    if (!canStartAppleOauth) return;

    appleOauthLoading.value = true;
    _clearFeedback();

    try {
      final credential = await _appleOAuth.signIn();
      if (credential == null) return;

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
        location: authLocation,
      );

      await _persistTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        provider: 'apple',
      );
      await _finishAuthenticatedFlow();
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      appleOauthLoading.value = false;
    }
  }

  Future<void> registerWithEmail() async {
    if (!canRegister) {
      error.value =
          nameError ??
          registerPhoneError ??
          emailError ??
          passwordError ??
          'Please fix highlighted fields.';
      return;
    }

    isLoading.value = true;
    _clearFeedback();

    try {
      final normalized = normalizedPhone;
      final result = await _authApi.registerWithEmail(
        email: email.value.trim(),
        password: password.value.trim(),
        phone: normalized,
        name: name.value.trim().isEmpty ? null : name.value.trim(),
      );

      final user = result.user;
      final userPhone = user?['phone']?.toString().trim();
      final phoneVerified = _readBool(user?['phoneVerified']);

      if ((userPhone?.isNotEmpty ?? false) && !phoneVerified) {
        Get.toNamed(
          AuthRoutes.verifyPhone,
          arguments: {
            'phone': userPhone,
            'email': email.value.trim(),
            'autoSend': true,
            'contextLabel': 'register',
          },
        );
        return;
      }

      await _persistTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      await _finishAuthenticatedFlow();
    } catch (e) {
      error.value = _prettyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _persistTokens({
    required String accessToken,
    String? refreshToken,
    String provider = 'email',
  }) async {
    await _tokenStorage.saveAccessToken(accessToken.trim());
    await _tokenStorage.saveAuthProvider(provider);
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      await _tokenStorage.saveRefreshToken(refreshToken.trim());
    } else {
      await _tokenStorage.deleteRefreshToken();
    }
  }

  Future<void> _finishAuthenticatedFlow() async {
    final session = Get.find<SessionController>();
    await session.bootstrap();
    Get.offAllNamed(AppRoutes.shell);
  }

  void _resetOtpState() {
    otpSent.value = false;
    loginOtp.value = '';
  }

  void _clearFeedback() {
    error.value = null;
    message.value = null;
  }

  bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
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
}
