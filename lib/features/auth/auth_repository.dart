import 'package:dio/dio.dart';
import '../../core/network/api_response.dart';
import '../../core/network/auth_endpoints.dart';
import '../../core/storage/secure_storage_service.dart';
import 'auth_models.dart';

abstract interface class AuthRepository {
  Future<AuthResult> signIn(String email, String password);
  Future<AuthResult> register(String name, String email, String password);
  Future<AuthUser?> restore();
  Future<void> signOut();
}

/// Simulation only: ANY valid email + eight-character password is accepted.
/// Passwords are validated for form shape, never stored, checked or transmitted.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this.storage);
  final SecureStorageService storage;
  final Map<String, AuthUser> _users = {};
  AuthResult _result(AuthUser user) => AuthResult(
    user: user,
    tokens: AuthTokens(
      accessToken: 'mock-access-${user.id}',
      refreshToken: 'mock-refresh-${user.id}',
    ),
  );
  @override
  Future<AuthResult> signIn(String email, String password) async {
    final normalized = AuthValidation.email(email);
    AuthValidation.password(password);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final user = _users.putIfAbsent(
      normalized,
      () => AuthUser(
        id: 'mock-${Uri.encodeComponent(normalized)}',
        email: normalized,
        name: 'Mock Guest',
      ),
    );
    return _result(user);
  }

  @override
  Future<AuthResult> register(
    String name,
    String email,
    String password,
  ) async {
    final normalized = AuthValidation.email(email);
    final displayName = AuthValidation.name(name);
    AuthValidation.password(password);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (_users.containsKey(normalized))
      throw const AuthException(
        'This email is already registered in this mock session.',
      );
    final user = AuthUser(
      id: 'mock-${Uri.encodeComponent(normalized)}',
      email: normalized,
      name: displayName,
    );
    _users[normalized] = user;
    return _result(user);
  }

  @override
  Future<AuthUser?> restore() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return storage.withSessionLock(() async {
      if (!await storage.hasToken()) return null;
      final id = await storage.getUserId();
      for (final user in _users.values) {
        if (user.id == id) return user;
      }
      await storage.clearAll();
      return null;
    });
  }

  @override
  Future<void> signOut() async {
    storage.invalidateSession();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await storage.withSessionLock(storage.clearAll);
  }
}

class DioAuthRepository implements AuthRepository {
  DioAuthRepository({
    required this.dio,
    required this.endpoints,
    required this.storage,
  });
  final Dio dio;
  final AuthEndpoints endpoints;
  final SecureStorageService storage;
  Future<T> _request<T>(
    Future<Response<dynamic>> Function() request,
    T Function(Object?) parse,
  ) async {
    try {
      final response = await request();
      return ApiResponse<T>.fromJson(
        Map<String, dynamic>.from(response.data as Map),
        parse,
      ).data;
    } on DioException catch (error) {
      throw NetworkFailure.fromDio(error);
    } on FormatException {
      throw const NetworkFailure(
        NetworkFailureKind.invalidResponse,
        'Invalid service response.',
      );
    } on TypeError {
      throw const NetworkFailure(
        NetworkFailureKind.invalidResponse,
        'Invalid service response.',
      );
    }
  }

  AuthResult _parseResult(Object? data) =>
      AuthResult.fromJson(Map<String, dynamic>.from(data as Map));
  @override
  Future<AuthResult> signIn(String email, String password) {
    final normalized = AuthValidation.email(email);
    AuthValidation.password(password);
    return _request(
      () => dio.post<dynamic>(
        endpoints.signIn,
        data: {'email': normalized, 'password': password},
        options: Options(extra: {'skipAuth': true}),
      ),
      _parseResult,
    );
  }

  @override
  Future<AuthResult> register(String name, String email, String password) {
    final normalized = AuthValidation.email(email);
    final displayName = AuthValidation.name(name);
    AuthValidation.password(password);
    return _request(
      () => dio.post<dynamic>(
        endpoints.register,
        data: {'name': displayName, 'email': normalized, 'password': password},
        options: Options(extra: {'skipAuth': true}),
      ),
      _parseResult,
    );
  }

  @override
  Future<AuthUser?> restore() async {
    if (!await storage.hasToken()) return null;
    return _request(
      () => dio.get<dynamic>(endpoints.currentUser),
      (data) => AuthUser.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<void> signOut() async {
    storage.invalidateSession();
    try {
      if (await storage.hasToken()) {
        await dio.post<dynamic>(
          endpoints.signOut,
          options: Options(extra: {'skipRefresh': true}),
        );
      }
    } on DioException catch (error) {
      throw NetworkFailure.fromDio(error);
    } finally {
      await storage.withSessionLock(storage.clearAll);
    }
  }
}
