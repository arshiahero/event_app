class AuthUser {
  const AuthUser({required this.id, required this.email, required this.name});
  final String id;
  final String email;
  final String name;
  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: _requiredString(json, 'id'),
    email: _requiredString(json, 'email'),
    name: _requiredString(json, 'name'),
  );
  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name};
}

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});
  final String accessToken;
  final String refreshToken;
  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: _requiredString(json, 'access_token'),
    refreshToken: _requiredString(json, 'refresh_token'),
  );
}

class AuthResult {
  const AuthResult({required this.user, required this.tokens});
  final AuthUser user;
  final AuthTokens tokens;

  /// Contract: {"user": {id, email, name}, "tokens": {access_token, refresh_token}}.
  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    user: AuthUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    tokens: AuthTokens.fromJson(
      Map<String, dynamic>.from(json['tokens'] as Map),
    ),
  );
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty)
    throw FormatException('Invalid $key.');
  return value;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract final class AuthValidation {
  static String email(String value) {
    final normalized = value.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
      throw const AuthException('Enter a valid email address.');
    }
    return normalized;
  }

  static String name(String value) {
    final normalized = value.trim();
    if (normalized.length < 2 || normalized.length > 100) {
      throw const AuthException('Name must contain 2–100 characters.');
    }
    return normalized;
  }

  static void password(String value) {
    if (value.trim().isEmpty || value.length < 8) {
      throw const AuthException('Password must contain at least 8 characters.');
    }
  }
}
