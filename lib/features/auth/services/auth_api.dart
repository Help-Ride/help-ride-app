import '../../../shared/services/api_client.dart';
import '../../../shared/models/location_sample.dart';

class AuthApi {
  AuthApi(this._client);
  final ApiClient _client;

  // ✅ This is what your UI expects (email/password)
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
