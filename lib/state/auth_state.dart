import 'package:flutter/foundation.dart';
import '../models/auth.dart';
import '../services/token_store.dart';
import '../services/vault_api.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthState extends ChangeNotifier {
  final TokenStore _store;
  final VaultApi _api;

  AuthState(this._store, this._api);

  AuthStatus _status = AuthStatus.unknown;
  String? _role;

  AuthStatus get status => _status;
  String? get role => _role;

  bool hasRole(List<String> roles) =>
      _role != null && roles.map((r) => r.toLowerCase()).contains(_role!.toLowerCase());

  /// Called at startup: restores session if a token is present.
  Future<void> bootstrap() async {
    final token = await _store.accessToken;
    _role = await _store.role;
    _status = (token != null && token.isNotEmpty)
        ? AuthStatus.signedIn
        : AuthStatus.signedOut;
    notifyListeners();
  }

  Future<LoginResult> login(String username, String password,
      {String? totpCode}) async {
    final result =
        await _api.login(username, password, totpCode: totpCode);
    if (result.outcome == LoginOutcome.success && result.response != null) {
      final r = result.response!;
      await _store.save(
          access: r.accessToken, refresh: r.refreshToken, role: r.role);
      _role = r.role;
      _status = AuthStatus.signedIn;
      notifyListeners();
    }
    return result;
  }

  Future<void> logout() async {
    final refresh = await _store.refreshToken;
    if (refresh != null) await _api.logout(refresh);
    await _store.clear();
    _role = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  /// Invoked when a refresh fails mid-session.
  Future<void> forceSignOut() async {
    await _store.clear();
    _role = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }
}
