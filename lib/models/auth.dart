class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
  final String role;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.role,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> j) => LoginResponse(
        accessToken: j['accessToken'] as String,
        refreshToken: j['refreshToken'] as String,
        accessTokenExpiresAt:
            DateTime.parse(j['accessTokenExpiresAt'] as String),
        role: j['role'] as String? ?? 'Unknown',
      );
}

/// Outcome of a login attempt, distinguishing the API's special states.
enum LoginOutcome { success, twoFactorRequired, invalidCredentials, locked, error }

class LoginResult {
  final LoginOutcome outcome;
  final LoginResponse? response;
  final String? message;
  LoginResult(this.outcome, {this.response, this.message});
}
