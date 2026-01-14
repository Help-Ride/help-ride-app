class ChatParticipant {
  final String id;
  final String name;
  final String role;
  final double? rating;
  final String? avatarUrl;
  final bool isOnline;

  ChatParticipant({
    required this.id,
    required this.name,
    required this.role,
    this.rating,
    this.avatarUrl,
    required this.isOnline,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: _readString(json, ['id', 'userId', 'participantId']),
      name: _readString(json, ['name', 'fullName', 'displayName'], fallback: 'User'),
      role: _readString(json, ['role', 'userRole'], fallback: 'passenger'),
      rating: _readDouble(json, ['rating', 'avgRating']),
      avatarUrl: _readString(
        json,
        ['avatarUrl', 'photoUrl', 'image', 'providerAvatarUrl'],
        fallback: '',
      ),
      isOnline: _readBool(json, ['isOnline', 'online'], fallback: false),
    );
  }

  ChatParticipant copyWith({
    String? id,
    String? name,
    String? role,
    double? rating,
    String? avatarUrl,
    bool? isOnline,
  }) {
    return ChatParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      rating: rating ?? this.rating,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
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

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

bool _readBool(
  Map<String, dynamic> json,
  List<String> keys, {
  bool fallback = false,
}) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
  }
  return fallback;
}
