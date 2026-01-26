import '../../../shared/services/api_client.dart';

class AuthApi {
  AuthApi(this._client);
  final ApiClient _client;

  // ✅ This is what your UI expects (email/password)
  Future<EmailLoginResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
      skipAuthLogout: true,
      skipAuthRefresh: true,
    );

    final data = res.data ?? {};
    if (data['user'] is Map) {
      return EmailLoginResult(otpSent: true);
    }
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
    String? name, // optional if backend supports it
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/register', // change if your backend uses /auth/signup
      skipAuthLogout: true,
      skipAuthRefresh: true,
      data: {
        'email': email,
        'password': password,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      },
    );

    final data = res.data ?? {};
    if (data['user'] is Map) {
      return EmailRegisterResult(otpSent: true);
    }
    final tokens = _parseTokens(data);
    if (tokens == null) {
      throw Exception('Missing accessToken in response');
    }
    return EmailRegisterResult(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
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

  Future<VerifyEmailResult?> verifyEmailOtp({
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
    final user = data['user'];
    return VerifyEmailResult(
      tokens: tokens,
      user: user is Map ? Map<String, dynamic>.from(user) : null,
    );
  }

  AuthTokens? _parseTokens(Map<String, dynamic> data) {
    final access = data['accessToken'];
    final refresh = data['refreshToken'];
    if (access is String && access.isNotEmpty) {
      return AuthTokens(
        accessToken: access,
        refreshToken:
            refresh is String && refresh.isNotEmpty ? refresh : null,
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

class VerifyEmailResult {
  final AuthTokens? tokens;
  final Map<String, dynamic>? user;

  VerifyEmailResult({this.tokens, this.user});
}

class EmailLoginResult {
  final String? accessToken;
  final String? refreshToken;
  final bool otpSent;

  EmailLoginResult({
    this.accessToken,
    this.refreshToken,
    this.otpSent = false,
  });
}

class EmailRegisterResult {
  final String? accessToken;
  final String? refreshToken;
  final bool otpSent;

  EmailRegisterResult({
    this.accessToken,
    this.refreshToken,
    this.otpSent = false,
  });
}
