import 'package:flutter/cupertino.dart';

import '../../../shared/services/api_client.dart';

class AuthApi {
  AuthApi(this._client);
  final ApiClient _client;

  // ✅ This is what your UI expects (email/password)
  Future<String> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
      skipAuthLogout: true,
    );

    debugPrint('Login API status: ${res.statusCode}');
    debugPrint('Login API response: ${res.data}');

    final data = res.data ?? {};
    final tokens = data['tokens'] as Map<String, dynamic>?;
    final token = tokens?['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Missing accessToken in response');
    }
    return token;
  }

  // Optional: verify token / get user
  Future<Map<String, dynamic>> me() async {
    final res = await _client.get<Map<String, dynamic>>('/auth/me');
    return res.data ?? {};
  }

  // ✅ Register (email/password)
  Future<String> registerWithEmail({
    required String email,
    required String password,
    String? name, // optional if backend supports it
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/register', // change if your backend uses /auth/signup
      skipAuthLogout: true,
      data: {
        'email': email,
        'password': password,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      },
    );

    final data = res.data ?? {};
    final tokens = data['tokens'] as Map<String, dynamic>?;
    final token = tokens?['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Missing accessToken in response');
    }
    return token;
  }
}
