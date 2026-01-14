import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import 'chat_api.dart';

class ChatPusherService {
  ChatPusherService(this._api);

  final ChatApi _api;
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  bool _initialized = false;
  bool _connected = false;
  String? _conversationChannelName;
  String? _userChannelName;

  Future<void> connect() async {
    final apiKey = dotenv.env['PUSHER_KEY'];
    final cluster = dotenv.env['PUSHER_CLUSTER'];
    if (apiKey == null || apiKey.isEmpty || cluster == null || cluster.isEmpty) {
      return;
    }

    if (!_initialized) {
      await _pusher.init(
        apiKey: apiKey,
        cluster: cluster,
        onConnectionStateChange: (_, __) {},
        onError: (_, __, ___) {},
        onAuthorizer: (String channelName, String socketId, dynamic options) async {
          return _api.pusherAuth(socketId: socketId, channelName: channelName);
        },
      );
      _initialized = true;
    }

    if (!_connected) {
      await _pusher.connect();
      _connected = true;
    }
  }

  Future<void> subscribeToConversation(
    String conversationId, {
    required void Function(ChatMessage message) onMessage,
  }) async {
    await connect();
    if (!_connected) return;

    final channelName = 'private-conversation-$conversationId';
    if (_conversationChannelName != null &&
        _conversationChannelName != channelName) {
      await _pusher.unsubscribe(channelName: _conversationChannelName!);
    }
    _conversationChannelName = channelName;

    await _pusher.subscribe(
      channelName: channelName,
      onEvent: (event) {
        final message = _messageFromEvent(event);
        if (message != null) {
          onMessage(message);
        }
      },
    );
  }

  Future<void> subscribeToUserConversations(
    String userId, {
    required String currentUserId,
    String? currentRole,
    required void Function(ChatConversation conversation) onConversationUpdated,
    VoidCallback? onUnknownPayload,
  }) async {
    await connect();
    if (!_connected) return;

    final channelName = 'private-user-$userId';
    if (_userChannelName != null && _userChannelName != channelName) {
      await _pusher.unsubscribe(channelName: _userChannelName!);
    }
    _userChannelName = channelName;

    await _pusher.subscribe(
      channelName: channelName,
      onEvent: (event) {
        if (event.eventName != 'conversation:updated') return;
        final conversation = _conversationFromEvent(
          event,
          currentUserId: currentUserId,
          currentRole: currentRole,
        );
        if (conversation != null) {
          onConversationUpdated(conversation);
          return;
        }
        onUnknownPayload?.call();
      },
    );
  }

  Future<void> unsubscribeFromConversation() async {
    if (_conversationChannelName != null) {
      await _pusher.unsubscribe(channelName: _conversationChannelName!);
      _conversationChannelName = null;
    }
  }

  Future<void> unsubscribeFromUserConversations() async {
    if (_userChannelName != null) {
      await _pusher.unsubscribe(channelName: _userChannelName!);
      _userChannelName = null;
    }
  }

  Future<void> disconnect() async {
    await unsubscribeFromConversation();
    await unsubscribeFromUserConversations();
    if (_connected) {
      await _pusher.disconnect();
      _connected = false;
    }
  }

  ChatMessage? _messageFromEvent(PusherEvent event) {
    final payload = _decodePayload(event.data);
    if (payload == null) return null;

    final Map<String, dynamic> messageJson =
        payload['message'] is Map<String, dynamic>
            ? payload['message'] as Map<String, dynamic>
            : payload;

    if (!messageJson.containsKey('conversationId')) return null;
    return ChatMessage.fromJson(messageJson);
  }

  ChatConversation? _conversationFromEvent(
    PusherEvent event, {
    required String currentUserId,
    String? currentRole,
  }) {
    final payload = _decodePayload(event.data);
    if (payload == null) return null;

    Map<String, dynamic>? conversationJson;
    if (payload['conversation'] is Map) {
      conversationJson = Map<String, dynamic>.from(payload['conversation'] as Map);
    } else if (payload['data'] is Map) {
      conversationJson = Map<String, dynamic>.from(payload['data'] as Map);
    } else if (payload.containsKey('id') ||
        payload.containsKey('conversationId')) {
      conversationJson = Map<String, dynamic>.from(payload);
    }

    if (conversationJson == null) return null;
    return ChatConversation.fromJson(
      conversationJson,
      currentUserId: currentUserId,
      currentRole: currentRole,
    );
  }

  Map<String, dynamic>? _decodePayload(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
