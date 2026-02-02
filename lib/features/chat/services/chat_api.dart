import 'package:help_ride/shared/services/api_client.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';

class ChatApi {
  ChatApi(this._client);
  final ApiClient _client;

  Future<List<ChatConversation>> listConversations({
    required String currentUserId,
    String? currentRole,
  }) async {
    final res = await _client.get('/chat/conversations');
    final data = res.data;
    if (data is List) {
      return _toMapList(data)
          .map(
            (item) => ChatConversation.fromJson(
              item,
              currentUserId: currentUserId,
              currentRole: currentRole,
            ),
          )
          .toList();
    }
    if (data is Map && data['data'] is List) {
      return _toMapList(data['data'])
          .map(
            (item) => ChatConversation.fromJson(
              item,
              currentUserId: currentUserId,
              currentRole: currentRole,
            ),
          )
          .toList();
    }
    return [];
  }

  Future<ChatConversation> createOrGetConversation({
    required String rideId,
    required String passengerId,
    required String currentUserId,
    String? currentRole,
  }) async {
    final res = await _client.post(
      '/chat/conversations',
      data: {'rideId': rideId, 'passengerId': passengerId},
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return ChatConversation.fromJson(
        data,
        currentUserId: currentUserId,
        currentRole: currentRole,
      );
    }
    if (data is Map && data['data'] is Map<String, dynamic>) {
      return ChatConversation.fromJson(
        data['data'],
        currentUserId: currentUserId,
        currentRole: currentRole,
      );
    }
    throw Exception('Invalid conversation payload');
  }

  Future<ChatMessagesPage> listMessagesPage(
    String conversationId, {
    int limit = 50,
    String? cursor,
  }) async {
    final res = await _client.get(
      '/chat/conversations/$conversationId/messages',
      query: {
        'limit': limit,
        if (cursor != null && cursor.trim().isNotEmpty) 'cursor': cursor.trim(),
      },
    );
    final data = res.data;
    if (data is Map) {
      final messagesList = data['messages'] is List
          ? data['messages'] as List
          : (data['data'] is List
                ? data['data'] as List
                : (data['data'] is Map && data['data']['messages'] is List
                      ? data['data']['messages'] as List
                      : null));
      if (messagesList != null) {
        return ChatMessagesPage(
          messages: _toMapList(messagesList).map(ChatMessage.fromJson).toList(),
          nextCursor: _readCursor(data),
        );
      }
    }
    if (data is List) {
      return ChatMessagesPage(
        messages: _toMapList(data).map(ChatMessage.fromJson).toList(),
        nextCursor: null,
      );
    }
    return const ChatMessagesPage(messages: <ChatMessage>[], nextCursor: null);
  }

  Future<List<ChatMessage>> listMessages(
    String conversationId, {
    int limit = 50,
    String? cursor,
  }) async {
    final page = await listMessagesPage(
      conversationId,
      limit: limit,
      cursor: cursor,
    );
    return page.messages;
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String body,
  }) async {
    final res = await _client.post(
      '/chat/conversations/$conversationId/messages',
      data: {'body': body},
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return ChatMessage.fromJson(data);
    }
    if (data is Map && data['data'] is Map<String, dynamic>) {
      return ChatMessage.fromJson(data['data']);
    }
    throw Exception('Invalid message payload');
  }

  Future<MarkMessagesReadResult> markConversationRead(
    String conversationId,
  ) async {
    final id = conversationId.trim();
    if (id.isEmpty) {
      return const MarkMessagesReadResult(
        conversationId: '',
        readCount: 0,
        readAt: null,
        messageIds: <String>[],
      );
    }
    final res = await _client.post('/chat/conversations/$id/read');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return MarkMessagesReadResult.fromJson(data);
    }
    if (data is Map && data['data'] is Map<String, dynamic>) {
      return MarkMessagesReadResult.fromJson(
        data['data'] as Map<String, dynamic>,
      );
    }
    return MarkMessagesReadResult(
      conversationId: id,
      readCount: 0,
      readAt: null,
      messageIds: const <String>[],
    );
  }

  Future<int> countUnreadMessages({
    required String conversationId,
    required String currentUserId,
    int limit = 50,
  }) async {
    final id = conversationId.trim();
    if (id.isEmpty) return 0;

    var unread = 0;
    String? cursor;
    final seenCursors = <String>{};

    while (true) {
      final page = await listMessagesPage(id, limit: limit, cursor: cursor);
      for (final message in page.messages) {
        if (message.readAt == null && message.senderId != currentUserId) {
          unread += 1;
        }
      }
      final nextCursor = page.nextCursor?.trim();
      if (nextCursor == null || nextCursor.isEmpty) break;
      if (seenCursors.contains(nextCursor)) break;
      seenCursors.add(nextCursor);
      cursor = nextCursor;
    }

    return unread;
  }

  Future<Map<String, dynamic>> pusherAuth({
    required String socketId,
    required String channelName,
  }) async {
    final res = await _client.post(
      '/chat/pusher/auth',
      data: {'socket_id': socketId, 'channel_name': channelName},
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    throw Exception('Invalid pusher auth payload');
  }
}

class ChatMessagesPage {
  const ChatMessagesPage({required this.messages, required this.nextCursor});

  final List<ChatMessage> messages;
  final String? nextCursor;
}

class MarkMessagesReadResult {
  const MarkMessagesReadResult({
    required this.conversationId,
    required this.readCount,
    required this.readAt,
    required this.messageIds,
  });

  final String conversationId;
  final int readCount;
  final DateTime? readAt;
  final List<String> messageIds;

  factory MarkMessagesReadResult.fromJson(Map<String, dynamic> json) {
    return MarkMessagesReadResult(
      conversationId: (json['conversationId'] ?? '').toString(),
      readCount: _readInt(json['readCount']),
      readAt: _readDateTime(json['readAt']),
      messageIds: _readStringList(json['messageIds']),
    );
  }
}

String? _readCursor(Map<dynamic, dynamic> map) {
  final direct = map['nextCursor'] ?? map['next_cursor'];
  final nested = map['data'] is Map
      ? ((map['data'] as Map)['nextCursor'] ??
            (map['data'] as Map)['next_cursor'])
      : null;
  final value = (direct ?? nested)?.toString().trim();
  if (value == null || value.isEmpty) return null;
  return value;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _readDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
  }
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}

List<String> _readStringList(dynamic value) {
  if (value is List) {
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  return const <String>[];
}

List<Map<String, dynamic>> _toMapList(dynamic value) {
  if (value is List) {
    return value.whereType<Map>().map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }
  return [];
}
