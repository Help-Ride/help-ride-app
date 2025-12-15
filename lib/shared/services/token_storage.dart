import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessKey = 'access_token';
  final _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessKey, value: token);

  Future<String?> getAccessToken() => _storage.read(key: _accessKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
  }
}
