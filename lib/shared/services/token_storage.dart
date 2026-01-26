import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _providerKey = 'auth_provider';
  static const _deviceTokenKey = 'device_token_registered';
  static const _deviceTokenCachedKey = 'device_token_cached';
  final _storage = const FlutterSecureStorage();

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

  Future<void> saveDeviceToken(String token) =>
      _storage.write(key: _deviceTokenKey, value: token);

  Future<String?> getDeviceToken() => _storage.read(key: _deviceTokenKey);

  Future<void> deleteDeviceToken() => _storage.delete(key: _deviceTokenKey);

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
  }
}
