class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderRole;
  final String body;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final senderJson = json['sender'];
    final senderId = _readString(json, ['senderId', 'userId', 'fromId']);
    String resolvedSenderId = senderId;
    if (resolvedSenderId.isEmpty && senderJson is Map<String, dynamic>) {
      resolvedSenderId = _readString(senderJson, ['id', 'userId']);
    }

    return ChatMessage(
      id: _readString(json, ['id', 'messageId']),
      conversationId: _readString(json, ['conversationId', 'threadId']),
      senderId: resolvedSenderId,
      senderRole: _readString(json, ['senderRole', 'role'], fallback: 'passenger'),
      body: _readString(json, ['body', 'text', 'message'], fallback: ''),
      createdAt: _readDateTime(json, ['createdAt', 'sentAt', 'timestamp']) ??
          DateTime.now(),
    );
  }

  static ChatMessage pending({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String body,
  }) {
    return ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      senderRole: senderRole,
      body: body,
      createdAt: DateTime.now(),
    );
  }
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return fallback;
}

DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }
  }
  return null;
}
