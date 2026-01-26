import 'api_client.dart';

class NotificationsApi {
  NotificationsApi(this._client);
  final ApiClient _client;

  Future<void> registerToken({
    required String token,
    required String platform,
    bool skipAuthLogout = false,
  }) async {
    await _client.post<void>(
      '/notifications/tokens/register',
      data: {
        'token': token,
        'platform': platform,
      },
      skipAuthLogout: skipAuthLogout,
    );
  }

  Future<void> unregisterToken({
    required String token,
    bool skipAuthLogout = false,
  }) async {
    await _client.post<void>(
      '/notifications/tokens/unregister',
      data: {'token': token},
      skipAuthLogout: skipAuthLogout,
    );
  }
}
