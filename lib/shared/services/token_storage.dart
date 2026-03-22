import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _providerKey = 'auth_provider';
  static const _authDeviceIdKey = 'auth_device_id';
  static const _deviceTokenKey = 'device_token_registered';
  static const _deviceTokenCachedKey = 'device_token_cached';
  static const _deviceTokenRegisteredAtKey = 'device_token_registered_at';
  final _storage = const FlutterSecureStorage();
  static const _uuid = Uuid();

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessKey, value: token);

  Future<String?> getAccessToken() => _storage.read(key: _accessKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshKey, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  Future<void> deleteRefreshToken() => _storage.delete(key: _refreshKey);

  Future<void> saveAuthProvider(String provider) =>
      _storage.write(key: _providerKey, value: provider);

  Future<String?> getAuthProvider() => _storage.read(key: _providerKey);

  Future<void> deleteAuthProvider() => _storage.delete(key: _providerKey);

  Future<String> getOrCreateAuthDeviceId() async {
    final existing = await _storage.read(key: _authDeviceIdKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }

    final generated = _uuid.v4();
    await _storage.write(key: _authDeviceIdKey, value: generated);
    return generated;
  }

  Future<void> saveDeviceToken(String token) =>
      _storage.write(key: _deviceTokenKey, value: token);

  Future<String?> getDeviceToken() => _storage.read(key: _deviceTokenKey);

  Future<void> deleteDeviceToken() => _storage.delete(key: _deviceTokenKey);

  Future<void> saveDeviceTokenRegisteredAt(DateTime dateTime) => _storage.write(
    key: _deviceTokenRegisteredAtKey,
    value: dateTime.toUtc().toIso8601String(),
  );

  Future<DateTime?> getDeviceTokenRegisteredAt() async {
    final raw = await _storage.read(key: _deviceTokenRegisteredAtKey);
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return null;
    return parsed.toUtc();
  }

  Future<void> deleteDeviceTokenRegisteredAt() =>
      _storage.delete(key: _deviceTokenRegisteredAtKey);

  Future<void> saveCachedDeviceToken(String token) =>
      _storage.write(key: _deviceTokenCachedKey, value: token);

  Future<String?> getCachedDeviceToken() =>
      _storage.read(key: _deviceTokenCachedKey);

  Future<void> deleteCachedDeviceToken() =>
      _storage.delete(key: _deviceTokenCachedKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _providerKey);
    await _storage.delete(key: _deviceTokenKey);
    await _storage.delete(key: _deviceTokenCachedKey);
    await _storage.delete(key: _deviceTokenRegisteredAtKey);
  }
}
