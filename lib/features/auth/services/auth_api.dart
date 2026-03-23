import '../../../shared/services/api_client.dart';
import '../../../shared/models/location_sample.dart';

class AuthApi {
  AuthApi(this._client);
  final ApiClient _client;

  // Legacy password auth kept for migration only.
  Future<EmailLoginResult> loginWithEmail({
    required String email,
    required String password,
    LocationSample? location,
  }) async {
    final payload = <String, dynamic>{
      'email': email,
      'password': password,
      if (location != null) ...location.toApiJson(),
    };
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: payload,
      skipAuthLogout: true,
      skipAuthRefresh: true,
    );

    final data = res.data ?? {};
    final tokens = _parseTokens(data);
    if (tokens == null) {
      throw Exception('Missing accessToken in response');
    }
    return EmailLoginResult(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  // Optional: verify token / get user
  Future<Map<String, dynamic>> me() async {
    final res = await _client.get<Map<String, dynamic>>('/auth/me');
    return res.data ?? {};
  }

  // ✅ Register (email/password)
  Future<EmailRegisterResult> registerWithEmail({
    required String email,
    required String password,
    String? phone,
    String? name, // optional if backend supports it
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/register', // change if your backend uses /auth/signup
      skipAuthLogout: true,
      skipAuthRefresh: true,
      data: {
        'email': email,
        'password': password,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      },
    );

    final data = res.data ?? {};
    final tokens = _parseTokens(data);
    if (tokens == null) {
      throw Exception('Missing accessToken in response');
    }
    return EmailRegisterResult(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: _parseUser(data),
    );
  }

  Future<void> sendVerifyEmailOtp({required String email}) async {
    await _client.post<Map<String, dynamic>>(
      '/auth/verify-email/send-otp',
      skipAuthLogout: true,
      skipAuthRefresh: true,
      data: {'email': email},
    );
  }

  Future<void> sendLoginEmailOtp({required String email}) async {
    await _client.post<Map<String, dynamic>>(
      '/auth/login-email/send-otp',
      skipAuthLogout: true,
      skipAuthRefresh: true,
      data: {'email': email},
    );
  }

  Future<OtpVerificationResult?> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/verify-email/verify-otp',
      skipAuthLogout: true,
      skipAuthRefresh: true,
      data: {'email': email, 'otp': otp},
    );
    final data = res.data ?? {};
    final tokens = _parseTokens(data);
    return OtpVerificationResult(tokens: tokens, user: _parseUser(data));
  }

  Future<void> sendVerifyPhoneOtp({required String phone}) async {
    await _client.post<Map<String, dynamic>>(
      '/auth/verify-phone/send-otp',
      skipAuthLogout: true,
      skipAuthRefresh: true,
      data: {'phone': phone},
    );
  }

  Future<void> sendLoginPhoneOtp({required String phone}) async {
    await _client.post<Map<String, dynamic>>(
      '/auth/login-phone/send-otp',
      skipAuthLogout: true,
      skipAuthRefresh: true,
      data: {'phone': phone},
    );
  }

  Future<OtpVerificationResult?> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/verify-phone/verify-otp',
      skipAuthLogout: true,
      skipAuthRefresh: true,
      data: {'phone': phone, 'otp': otp},
    );
    final data = res.data ?? {};
    final tokens = _parseTokens(data);
    return OtpVerificationResult(tokens: tokens, user: _parseUser(data));
  }

  Future<void> sendPasswordResetOtp({required String email}) async {
    await _client.post<Map<String, dynamic>>(
      '/auth/password-reset/send-otp',
      skipAuthLogout: true,
      skipAuthRefresh: true,
      data: {'email': email},
    );
  }

  Future<void> verifyPasswordResetOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _client.post<Map<String, dynamic>>(
      '/auth/password-reset/verify-otp',
      skipAuthLogout: true,
      skipAuthRefresh: true,
      data: {'email': email, 'otp': otp, 'newPassword': newPassword},
    );
  }

  Future<ContinueAuthSendResult> sendContinuePhoneOtp({
    required String phone,
    required String deviceId,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/continue/phone',
      skipAuthLogout: true,
      skipAuthRefresh: true,
      data: {
        'phone': phone,
        'deviceId': deviceId,
      },
    );
    final data = res.data ?? {};
    return ContinueAuthSendResult.fromJson(data);
  }

  Future<ContinueAuthSendResult> sendContinueEmailOtp({
    required String email,
    required String deviceId,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/continue/email',
      skipAuthLogout: true,
      skipAuthRefresh: true,
      data: {
        'email': email,
        'deviceId': deviceId,
      },
    );
    final data = res.data ?? {};
    return ContinueAuthSendResult.fromJson(data);
  }

  Future<ContinueAuthVerificationResult> verifyContinuePhoneOtp({
    required String phone,
    required String otp,
    required String deviceId,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/continue/phone/verify',
      skipAuthLogout: true,
      skipAuthRefresh: true,
      data: {
        'phone': phone,
        'otp': otp,
        'deviceId': deviceId,
      },
    );
    final data = res.data ?? {};
    return ContinueAuthVerificationResult.fromJson(
      data,
      tokens: _parseTokens(data),
      user: _parseUser(data),
    );
  }

  Future<ContinueAuthVerificationResult> verifyContinueEmailOtp({
    required String email,
    required String otp,
    required String deviceId,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/continue/email/verify',
      skipAuthLogout: true,
      skipAuthRefresh: true,
      data: {
        'email': email,
        'otp': otp,
        'deviceId': deviceId,
      },
    );
    final data = res.data ?? {};
    return ContinueAuthVerificationResult.fromJson(
      data,
      tokens: _parseTokens(data),
      user: _parseUser(data),
    );
  }

  Future<ContinueAuthVerificationResult> completeOnboarding({
    required String onboardingToken,
    required String firstName,
    required String lastName,
    required String deviceId,
    String? email,
    String? phone,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/onboarding/complete',
      skipAuthLogout: true,
      skipAuthRefresh: true,
      data: {
        'onboardingToken': onboardingToken,
        'firstName': firstName,
        'lastName': lastName,
        'deviceId': deviceId,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
    final data = res.data ?? {};
    return ContinueAuthVerificationResult.fromJson(
      data,
      tokens: _parseTokens(data),
      user: _parseUser(data),
    );
  }

  AuthTokens? _parseTokens(Map<String, dynamic> data) {
    final access = data['accessToken'];
    final refresh = data['refreshToken'];
    if (access is String && access.isNotEmpty) {
      return AuthTokens(
        accessToken: access,
        refreshToken: refresh is String && refresh.isNotEmpty ? refresh : null,
      );
    }

    final tokens = data['tokens'];
    if (tokens is Map && tokens['accessToken'] is String) {
      final t = tokens['accessToken'] as String;
      if (t.isNotEmpty) {
        final r = tokens['refreshToken'];
        return AuthTokens(
          accessToken: t,
          refreshToken: r is String && r.isNotEmpty ? r : null,
        );
      }
    }

    return null;
  }

  Map<String, dynamic>? _parseUser(Map<String, dynamic> data) {
    final user = data['user'];
    return user is Map ? Map<String, dynamic>.from(user) : null;
  }

  Future<AuthTokens> refreshToken({required String refreshToken}) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
      skipAuthLogout: true,
      skipAuthRefresh: true,
    );
    final data = res.data ?? {};
    final tokens = _parseTokens(data);
    if (tokens == null) {
      throw Exception('Missing accessToken in refresh response');
    }
    return tokens;
  }

  Future<void> logout({required String refreshToken}) async {
    await _client.post<Map<String, dynamic>>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
      skipAuthLogout: true,
      skipAuthRefresh: true,
    );
  }
}

class AuthTokens {
  final String accessToken;
  final String? refreshToken;

  AuthTokens({required this.accessToken, this.refreshToken});
}

class OtpVerificationResult {
  final AuthTokens? tokens;
  final Map<String, dynamic>? user;

  OtpVerificationResult({this.tokens, this.user});
}

class EmailLoginResult {
  final String accessToken;
  final String? refreshToken;

  EmailLoginResult({required this.accessToken, this.refreshToken});
}

class EmailRegisterResult {
  final String accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? user;

  EmailRegisterResult({
    required this.accessToken,
    this.refreshToken,
    this.user,
  });
}

class ContinueAuthSendResult {
  final String? message;
  final String? channel;
  final String? nextStep;
  final int resendAvailableInSeconds;

  ContinueAuthSendResult({
    this.message,
    this.channel,
    this.nextStep,
    this.resendAvailableInSeconds = 30,
  });

  factory ContinueAuthSendResult.fromJson(Map<String, dynamic> json) {
    return ContinueAuthSendResult(
      message: json['message']?.toString(),
      channel: json['channel']?.toString(),
      nextStep: json['nextStep']?.toString(),
      resendAvailableInSeconds:
          int.tryParse('${json['resendAvailableInSeconds'] ?? 30}') ?? 30,
    );
  }
}

class ContinueAuthVerificationResult {
  final AuthTokens? tokens;
  final Map<String, dynamic>? user;
  final String? nextStep;
  final bool isNewUser;
  final String? onboardingToken;
  final Map<String, dynamic>? onboarding;
  final bool needsPhoneVerification;

  ContinueAuthVerificationResult({
    this.tokens,
    this.user,
    this.nextStep,
    this.isNewUser = false,
    this.onboardingToken,
    this.onboarding,
    this.needsPhoneVerification = false,
  });

  factory ContinueAuthVerificationResult.fromJson(
    Map<String, dynamic> json, {
    AuthTokens? tokens,
    Map<String, dynamic>? user,
  }) {
    final onboarding = json['onboarding'];
    return ContinueAuthVerificationResult(
      tokens: tokens,
      user: user,
      nextStep: json['nextStep']?.toString(),
      isNewUser: json['isNewUser'] == true,
      onboardingToken: json['onboardingToken']?.toString(),
      onboarding: onboarding is Map<String, dynamic>
          ? onboarding
          : onboarding is Map
              ? Map<String, dynamic>.from(onboarding)
              : null,
      needsPhoneVerification: json['needsPhoneVerification'] == true,
    );
  }
}
