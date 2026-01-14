import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _providerKey = 'auth_provider';
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

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _providerKey);
  }
}
