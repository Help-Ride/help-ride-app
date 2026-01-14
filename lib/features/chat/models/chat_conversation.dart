import 'chat_participant.dart';

class ChatConversation {
  final String id;
  final String rideId;
  final String passengerId;
  final String driverId;
  final ChatParticipant passenger;
  final ChatParticipant driver;
  final ChatParticipant participant;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? tripSummary;
  final String? tripTimeLabel;

  ChatConversation({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.driverId,
    required this.passenger,
    required this.driver,
    required this.participant,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    this.tripSummary,
    this.tripTimeLabel,
  });

  factory ChatConversation.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
    String? currentRole,
  }) {
    final passengerJson = _readMap(json, ['passenger']);
    final driverJson = _readMap(json, ['driver']);

    final passengerId = _readString(json, ['passengerId', 'passenger_id']);
    final driverId = _readString(json, ['driverId', 'driver_id']);

    final passenger = passengerJson != null
        ? ChatParticipant.fromJson(passengerJson).copyWith(role: 'passenger')
        : ChatParticipant(
            id: passengerId,
            name: _readString(json, ['passengerName'], fallback: 'Passenger'),
            role: 'passenger',
            rating: _readDouble(json, ['passengerRating']),
            avatarUrl: _readString(
              json,
              ['passengerAvatar', 'passengerAvatarUrl'],
              fallback: '',
            ),
            isOnline: _readBool(json, ['passengerOnline'], fallback: false),
          );

    final driver = driverJson != null
        ? ChatParticipant.fromJson(driverJson).copyWith(role: 'driver')
        : ChatParticipant(
            id: driverId,
            name: _readString(json, ['driverName'], fallback: 'Driver'),
            role: 'driver',
            rating: _readDouble(json, ['driverRating']),
            avatarUrl: _readString(
              json,
              ['driverAvatar', 'driverAvatarUrl'],
              fallback: '',
            ),
            isOnline: _readBool(json, ['driverOnline'], fallback: false),
          );

    final lastMessagePreview = _readString(
      json,
      ['lastMessagePreview', 'lastMessage', 'last_message'],
      fallback: '',
    );

    final lastMessageAt = _readDateTime(
      json,
      ['lastMessageAt', 'updatedAt', 'createdAt'],
    );

    final isDriver = currentRole == 'driver' || currentUserId == driverId;
    final participant = isDriver ? passenger : driver;

    return ChatConversation(
      id: _readString(json, ['id', 'conversationId']),
      rideId: _readString(json, ['rideId', 'ride_id']),
      passengerId: passengerId,
      driverId: driverId,
      passenger: passenger,
      driver: driver,
      participant: participant,
      lastMessage: lastMessagePreview,
      lastMessageAt: lastMessageAt,
      unreadCount: _readInt(json, ['unreadCount', 'unread'], fallback: 0),
      tripSummary: _readString(json, ['tripSummary', 'routeSummary'], fallback: ''),
      tripTimeLabel: _readString(json, ['tripTime', 'pickupTime'], fallback: ''),
    );
  }

  ChatConversation copyWith({
    String? id,
    String? rideId,
    String? passengerId,
    String? driverId,
    ChatParticipant? passenger,
    ChatParticipant? driver,
    ChatParticipant? participant,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    String? tripSummary,
    String? tripTimeLabel,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      passengerId: passengerId ?? this.passengerId,
      driverId: driverId ?? this.driverId,
      passenger: passenger ?? this.passenger,
      driver: driver ?? this.driver,
      participant: participant ?? this.participant,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      tripSummary: tripSummary ?? this.tripSummary,
      tripTimeLabel: tripTimeLabel ?? this.tripTimeLabel,
    );
  }
}

Map<String, dynamic>? _readMap(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
  }
  return null;
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

int _readInt(
  Map<String, dynamic> json,
  List<String> keys, {
  int fallback = 0,
}) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
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

DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
    }
    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }
  }
  return null;
}
