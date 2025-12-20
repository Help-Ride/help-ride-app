import '../../../shared/services/api_client.dart';

class OAuthApi {
  OAuthApi(this._client);
  final ApiClient _client;

  Future<String> oauthLogin({
    required String provider,
    required String providerUserId,
    required String email,
    required String name,
    String? avatarUrl,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/oauth',
      data: {
        'provider': provider,
        'providerUserId': providerUserId,
        'email': email,
        'name': name,
        'avatarUrl': avatarUrl,
      },
    );

    final data = res.data ?? {};

    // common: { accessToken: "..." }
    final accessToken = data['accessToken'];
    if (accessToken is String && accessToken.isNotEmpty) return accessToken;

    // common: { tokens: { accessToken: "..." } }
    final tokens = data['tokens'];
    if (tokens is Map && tokens['accessToken'] is String) {
      final t = tokens['accessToken'] as String;
      if (t.isNotEmpty) return t;
    }

    throw Exception('OAuth login: invalid response shape');
  }
}
