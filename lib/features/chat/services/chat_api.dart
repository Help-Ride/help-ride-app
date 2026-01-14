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
          .map((item) => ChatConversation.fromJson(
                item,
                currentUserId: currentUserId,
                currentRole: currentRole,
              ))
          .toList();
    }
    if (data is Map && data['data'] is List) {
      return _toMapList(data['data'])
          .map((item) => ChatConversation.fromJson(
                item,
                currentUserId: currentUserId,
                currentRole: currentRole,
              ))
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
      data: {
        'rideId': rideId,
        'passengerId': passengerId,
      },
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

  Future<List<ChatMessage>> listMessages(
    String conversationId, {
    int limit = 50,
  }) async {
    final res = await _client.get(
      '/chat/conversations/$conversationId/messages',
      query: {'limit': limit},
    );
    final data = res.data;
    if (data is List) {
      return _toMapList(data).map(ChatMessage.fromJson).toList();
    }
    if (data is Map) {
      final messagesList = data['messages'] is List
          ? data['messages'] as List
          : (data['data'] is List
              ? data['data'] as List
              : (data['data'] is Map && data['data']['messages'] is List
                  ? data['data']['messages'] as List
                  : null));
      if (messagesList != null) {
        return _toMapList(messagesList).map(ChatMessage.fromJson).toList();
      }
    }
    if (data is Map && data['data'] is List) {
      return _toMapList(data['data']).map(ChatMessage.fromJson).toList();
    }
    return [];
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

  Future<Map<String, dynamic>> pusherAuth({
    required String socketId,
    required String channelName,
  }) async {
    final res = await _client.post(
      '/chat/pusher/auth',
      data: {
        'socket_id': socketId,
        'channel_name': channelName,
      },
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    throw Exception('Invalid pusher auth payload');
  }
}

List<Map<String, dynamic>> _toMapList(dynamic value) {
  if (value is List) {
    return value.whereType<Map>().map((item) {
      return Map<String, dynamic>.from(item as Map);
    }).toList();
  }
  return [];
}
