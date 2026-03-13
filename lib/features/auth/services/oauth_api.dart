import '../../../shared/services/api_client.dart';
import '../../../shared/models/location_sample.dart';

class OAuthApi {
  OAuthApi(this._client);
  final ApiClient _client;

  Future<OAuthTokens> oauthLogin({
    required String provider,
    required String providerUserId,
    String? email,
    String? name,
    String? avatarUrl,
    String? identityToken,
    LocationSample? location,
  }) async {
    final payload = <String, dynamic>{
      'provider': provider,
      'providerUserId': providerUserId,
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (avatarUrl != null && avatarUrl.trim().isNotEmpty)
        'avatarUrl': avatarUrl.trim(),
      if (identityToken != null && identityToken.trim().isNotEmpty)
        'identityToken': identityToken.trim(),
      if (location != null) ...location.toApiJson(),
    };
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/oauth',
      skipAuthLogout: true,
      skipAuthRefresh: true,
      data: payload,
    );

    final data = res.data ?? {};

    // common: { accessToken: "...", refreshToken: "..." }
    final directAccess = data['accessToken'];
    final directRefresh = data['refreshToken'];
    if (directAccess is String && directAccess.isNotEmpty) {
      return OAuthTokens(
        accessToken: directAccess,
        refreshToken: directRefresh is String && directRefresh.isNotEmpty
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
          refreshToken: r is String && r.isNotEmpty ? r : null,
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
