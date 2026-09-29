import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists JWT access + refresh tokens in the platform secure store
/// (iOS Keychain / Android EncryptedSharedPreferences).
class TokenStore {
  static const _kAccess = 'vault_access_token';
  static const _kRefresh = 'vault_refresh_token';
  static const _kRole = 'vault_role';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> save({
    required String access,
    required String refresh,
    required String role,
  }) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
    await _storage.write(key: _kRole, value: role);
  }

  Future<void> updateAccess(String access, String refresh) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<String?> get accessToken => _storage.read(key: _kAccess);
  Future<String?> get refreshToken => _storage.read(key: _kRefresh);
  Future<String?> get role => _storage.read(key: _kRole);

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kRole);
  }
}
