import 'api_client.dart';

class NotificationsApi {
  NotificationsApi(this._client);
  final ApiClient _client;

  Future<NotificationsPage> listNotifications({
    bool? isRead,
    int limit = 80,
    String? cursor,
  }) async {
    final res = await _client.get<dynamic>(
      '/notifications',
      query: {
        if (isRead != null) 'isRead': isRead.toString(),
        'limit': limit,
        if (cursor != null && cursor.trim().isNotEmpty) 'cursor': cursor.trim(),
      },
    );

    final data = res.data;
    if (data is Map) {
      final notificationsRaw = data['notifications'];
      final notifications = notificationsRaw is List
          ? notificationsRaw
                .whereType<Map>()
                .map((item) => item.cast<String, dynamic>())
                .toList()
          : const <Map<String, dynamic>>[];
      final nextCursor = (data['nextCursor'] ?? '').toString().trim();
      return NotificationsPage(
        notifications: notifications,
        nextCursor: nextCursor.isEmpty ? null : nextCursor,
      );
    }

    return const NotificationsPage(
      notifications: <Map<String, dynamic>>[],
      nextCursor: null,
    );
  }

  Future<void> markRead(String notificationId) async {
    final id = notificationId.trim();
    if (id.isEmpty) return;
    await _client.post<void>('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _client.post<void>('/notifications/read-all');
  }

  Future<void> registerToken({
    required String token,
    required String platform,
    bool skipAuthLogout = false,
  }) async {
    await _client.post<void>(
      '/notifications/tokens/register',
      data: {'token': token, 'platform': platform},
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

class NotificationsPage {
  const NotificationsPage({
    required this.notifications,
    required this.nextCursor,
  });

  final List<Map<String, dynamic>> notifications;
  final String? nextCursor;
}
