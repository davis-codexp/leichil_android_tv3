import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  AuthStorage._();

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _userId = 'user_id';
  static const String _name = 'user_name';
  static const String _mobile = 'mobile';
  static const String _token = 'token';

  static Future<void> saveData({
    required String id,
    required String name,
    required String mobile,
    required String token,
  }) async {
    await _storage.write(key: _userId, value: id);
    await _storage.write(key: _name, value: name);
    await _storage.write(key: _mobile, value: mobile);
    await _storage.write(key: _token, value: token);
  }

  static Future<String?> getUserId() async {
    return _storage.read(key: _userId);
  }

  static Future<String?> getName() async {
    return _storage.read(key: _name);
  }

  static Future<String?> getMobile() async {
    return _storage.read(key: _mobile);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _token);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}