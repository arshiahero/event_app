import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/network/infrastructure_providers.dart';
import '../../core/storage/secure_storage_service.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(secureStorageProvider);
  if (ref.watch(appConfigProvider).useMocks) return MockAuthRepository(storage);
  return DioAuthRepository(
    dio: ref.watch(dioClientProvider).dio,
    endpoints: ref.watch(authEndpointsProvider),
    storage: storage,
  );
});

/// Initially guest; restore is explicit, so app startup never performs network IO.
final authProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthUser?>>((ref) {
      final controller = AuthController(
        ref.watch(authRepositoryProvider),
        ref.watch(secureStorageProvider),
      );
      ref.listen<int>(
        sessionExpiredProvider,
        (_, __) => controller.sessionExpired(),
      );
      return controller;
    });

class AuthController extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthController(this.repository, this.storage) : super(const AsyncData(null));
  final AuthRepository repository;
  final SecureStorageService storage;
  Future<void>? _active;
  Future<void>? _logout;
  int _generation = 0;

  Future<void> _run(Future<AuthUser?> Function() operation) async {
    if (!mounted) throw const AuthException('Authentication is disposed.');
    if (_active != null || _logout != null) {
      throw const AuthException(
        'An authentication operation is already in progress.',
      );
    }
    _generation++;
    storage.invalidateSession();
    final done = Completer<void>();
    final barrier = done.future;
    _active = barrier;
    final generation = _generation;
    state = const AsyncLoading();
    try {
      final user = await operation();
      if (mounted && generation == _generation) state = AsyncData(user);
    } catch (error, stack) {
      // An explicitly cancelled operation must not overwrite guest/logout state.
      if (mounted && generation == _generation) {
        state = AsyncError(error, stack);
        rethrow;
      }
    } finally {
      if (identical(_active, barrier)) _active = null;
      done.complete();
    }
  }

  Future<AuthUser> _save(AuthResult result, int generation, int revision) =>
      storage.withSessionLock(() async {
        if (!mounted ||
            generation != _generation ||
            revision != storage.sessionRevision) {
          throw const AuthException('Session operation was invalidated.');
        }
        try {
          await storage.saveAccessToken(result.tokens.accessToken);
          await storage.saveRefreshToken(result.tokens.refreshToken);
          await storage.saveUserId(result.user.id);
          if (!mounted ||
              generation != _generation ||
              revision != storage.sessionRevision) {
            throw const AuthException('Session operation was invalidated.');
          }
          return result.user;
        } catch (_) {
          // Still inside the write lock: newer credentials cannot exist yet.
          await storage.clearAll();
          rethrow;
        }
      });

  Future<void> signIn(String email, String password) => _run(() async {
    final generation = _generation;
    final revision = storage.sessionRevision;
    return _save(
      await repository.signIn(email, password),
      generation,
      revision,
    );
  });
  Future<void> register(String name, String email, String password) =>
      _run(() async {
        final generation = _generation;
        final revision = storage.sessionRevision;
        return _save(
          await repository.register(name, email, password),
          generation,
          revision,
        );
      });
  Future<void> restore() => _run(repository.restore);
  Future<void> signOut() {
    final existing = _logout;
    if (existing != null) return existing;
    if (!mounted)
      return Future<void>.error(
        const AuthException('Authentication is disposed.'),
      );
    _generation++;
    storage.invalidateSession();
    final pending = _active;
    final done = Completer<void>();
    final logout = done.future;
    _logout = logout;
    state = const AsyncData(null);
    // Install the barrier before invoking any asynchronous logout work.
    unawaited(_finishLogout(pending, logout, done));
    return logout;
  }

  Future<void> _finishLogout(
    Future<void>? pending,
    Future<void> logout,
    Completer<void> done,
  ) async {
    try {
      if (pending != null) await pending;
      try {
        await repository.signOut();
      } finally {
        await storage.withSessionLock(storage.clearAll);
      }
      done.complete();
    } catch (error, stack) {
      done.completeError(error, stack);
    } finally {
      // Cleanup finishes before allowing a new sign-in, even on remote failure.
      if (identical(_logout, logout)) _logout = null;
      if (mounted) state = const AsyncData(null);
    }
  }

  /// Storage is cleared by DioClient before this notification is emitted.
  void sessionExpired() {
    _generation++;
    if (mounted) state = const AsyncData(null);
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}
