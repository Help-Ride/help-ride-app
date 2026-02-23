import 'package:geolocator/geolocator.dart';

import '../models/location_sample.dart';
import 'api_client.dart';
import 'token_storage.dart';

class UserLocationUpdate {
  const UserLocationUpdate({
    required this.userId,
    required this.lat,
    required this.lng,
    this.accuracyMeters,
    this.recordedAt,
    this.updatedAt,
  });

  final String userId;
  final double lat;
  final double lng;
  final double? accuracyMeters;
  final DateTime? recordedAt;
  final DateTime? updatedAt;

  factory UserLocationUpdate.fromJson(Map<String, dynamic> json) {
    return UserLocationUpdate(
      userId: _readString(json['userId'] ?? json['user_id']),
      lat: _readDouble(json['lat']),
      lng: _readDouble(json['lng']),
      accuracyMeters: _readNullableDouble(
        json['accuracyMeters'] ?? json['accuracy_meters'],
      ),
      recordedAt: _readDateTime(json['recordedAt'] ?? json['recorded_at']),
      updatedAt: _readDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }
}

class LocationSyncService {
  LocationSyncService._();

  static final LocationSyncService instance = LocationSyncService._();

  static const Duration _defaultTimeout = Duration(seconds: 10);
  static const Duration _minSyncInterval = Duration(minutes: 2);
  static const double _minMoveMeters = 100;

  final TokenStorage _tokenStorage = TokenStorage();

  ApiClient? _client;
  DateTime? _lastSyncedAt;
  LocationSample? _lastSyncedSample;

  Future<LocationSample?> captureCurrentLocation({
    bool requestPermission = false,
    bool allowLastKnown = true,
  }) async {
    final canAccess = await _ensureLocationAccess(
      requestPermission: requestPermission,
    );
    if (!canAccess) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: _defaultTimeout,
        ),
      );
      return LocationSample.fromPosition(position);
    } catch (_) {
      if (!allowLastKnown) return null;
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown == null) return null;
        return LocationSample.fromPosition(lastKnown);
      } catch (_) {
        return null;
      }
    }
  }

  Future<Map<String, dynamic>?> buildAuthLocationPayload({
    bool requestPermission = false,
  }) async {
    final sample = await captureCurrentLocation(
      requestPermission: requestPermission,
      allowLastKnown: true,
    );
    return sample?.toApiJson();
  }

  Future<UserLocationUpdate?> syncMyLocation({
    LocationSample? sample,
    bool requestPermission = false,
    bool force = false,
  }) async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      return null;
    }

    final resolvedSample =
        sample ??
        await captureCurrentLocation(
          requestPermission: requestPermission,
          allowLastKnown: true,
        );
    if (resolvedSample == null) return null;

    if (!force && _shouldSkipSync(resolvedSample)) {
      return null;
    }

    final client = await _getClient();
    final res = await client.put<Map<String, dynamic>>(
      '/users/me/location',
      data: resolvedSample.toApiJson(),
    );

    final data = _unwrapMap(res.data);
    final update = UserLocationUpdate.fromJson(data);

    _lastSyncedAt = DateTime.now().toUtc();
    _lastSyncedSample = resolvedSample;
    return update;
  }

  Future<bool> _ensureLocationAccess({required bool requestPermission}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  Future<ApiClient> _getClient() async {
    final existing = _client;
    if (existing != null) return existing;
    final client = await ApiClient.create();
    _client = client;
    return client;
  }

  bool _shouldSkipSync(LocationSample sample) {
    final lastAt = _lastSyncedAt;
    final lastSample = _lastSyncedSample;
    if (lastAt == null || lastSample == null) return false;

    final elapsed = DateTime.now().toUtc().difference(lastAt);
    if (elapsed >= _minSyncInterval) return false;

    final movedMeters = Geolocator.distanceBetween(
      lastSample.lat,
      lastSample.lng,
      sample.lat,
      sample.lng,
    );

    return movedMeters < _minMoveMeters;
  }
}

Map<String, dynamic> _unwrapMap(Map<String, dynamic>? raw) {
  if (raw == null) return const {};
  final data = raw['data'];
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return raw;
}

String _readString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text;
}

double _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _readNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _readDateTime(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}
