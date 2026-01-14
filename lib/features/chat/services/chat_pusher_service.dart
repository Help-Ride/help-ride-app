import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../models/chat_message.dart';
import 'chat_api.dart';

class ChatPusherService {
  ChatPusherService(this._api);

  final ChatApi _api;
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  bool _initialized = false;
  bool _connected = false;
  String? _channelName;

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
    if (_channelName != null && _channelName != channelName) {
      await _pusher.unsubscribe(channelName: _channelName!);
    }
    _channelName = channelName;

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

  Future<void> unsubscribe() async {
    if (_channelName != null) {
      await _pusher.unsubscribe(channelName: _channelName!);
      _channelName = null;
    }
  }

  Future<void> disconnect() async {
    await unsubscribe();
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
