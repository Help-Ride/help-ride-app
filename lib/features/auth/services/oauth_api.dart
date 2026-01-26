import '../../../shared/services/api_client.dart';

class OAuthApi {
  OAuthApi(this._client);
  final ApiClient _client;

  Future<OAuthTokens> oauthLogin({
    required String provider,
    required String providerUserId,
    required String email,
    required String name,
    String? avatarUrl,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/oauth',
      skipAuthLogout: true,
      skipAuthRefresh: true,
      data: {
        'provider': provider,
        'providerUserId': providerUserId,
        'email': email,
        'name': name,
        'avatarUrl': avatarUrl,
      },
    );

    final data = res.data ?? {};

    // common: { accessToken: "...", refreshToken: "..." }
    final directAccess = data['accessToken'];
    final directRefresh = data['refreshToken'];
    if (directAccess is String && directAccess.isNotEmpty) {
      return OAuthTokens(
        accessToken: directAccess,
        refreshToken:
            directRefresh is String && directRefresh.isNotEmpty
                ? directRefresh
                : null,
      );
    }

    // common: { tokens: { accessToken: "...", refreshToken: "..." } }
    final tokens = data['tokens'];
    if (tokens is Map && tokens['accessToken'] is String) {
      final t = tokens['accessToken'] as String;
      if (t.isNotEmpty) {
        final r = tokens['refreshToken'];
        return OAuthTokens(
          accessToken: t,
          refreshToken:
              r is String && r.isNotEmpty ? r : null,
        );
      }
    }

    throw Exception('OAuth login: invalid response shape');
  }
}

class OAuthTokens {
  final String accessToken;
  final String? refreshToken;

  OAuthTokens({required this.accessToken, this.refreshToken});
}
