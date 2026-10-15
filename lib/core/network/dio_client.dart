import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';
import '../../features/auth/auth_models.dart';

typedef RefreshTokens = Future<AuthTokens> Function(String refreshToken);

/// Caller guarantees a NEW, unconsumed body on each invocation.
/// Required for multipart/stream bodies; never return the original FormData.
typedef RetryBodyFactory = FutureOr<Object?> Function();

class DioClient {
  DioClient({
    required this.dio,
    required this.storage,
    required this.refreshTokens,
    required this.onSessionExpired,
    bool debugLogs = false,
  }) {
    _interceptor = InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          if (options.extra['skipAuth'] != true) {
            final revision = storage.sessionRevision;
            final token = await storage.getAccessToken();
            if (_disposed || revision != storage.sessionRevision) {
              throw StateError('Session changed before request.');
            }
            options.headers.removeWhere(
              (key, _) => key.toLowerCase() == 'authorization',
            );
            if (token != null && token.isNotEmpty)
              options.headers['Authorization'] = 'Bearer $token';
            if (options.extra['authRetried'] != true) {
              options.extra[_revisionKey] = revision;
              options.extra[_tokenKey] = token;
              try {
                options.extra[_bodyKey] = _copyBody(options.data);
                options.extra[_replayKey] = true;
              } catch (_) {
                options.extra[_replayKey] = false;
              }
            }
          }
          // No URI/query, headers, body, response contents or exception text.
          if (debugLogs && kDebugMode)
            debugPrint('API request [details redacted]');
          handler.next(options);
        } catch (error) {
          handler.reject(DioException(requestOptions: options, error: error));
        }
      },
      onResponse: (response, handler) {
        if (debugLogs && kDebugMode)
          debugPrint('API response: ${response.statusCode} [details redacted]');
        handler.next(response);
      },
      onError: (error, handler) async {
        final options = error.requestOptions;
        final revision = options.extra[_revisionKey];
        if (_disposed ||
            error.response?.statusCode != 401 ||
            options.extra['skipAuth'] == true ||
            options.extra['skipRefresh'] == true ||
            options.extra['authRetried'] == true ||
            revision is! int ||
            revision != storage.sessionRevision ||
            revision == _failedRevision ||
            options.extra[_tokenKey] == null) {
          handler.next(error);
          return;
        }
        try {
          final factory = options.extra['retryBodyFactory'];
          Object? body;
          if (factory is RetryBodyFactory) {
            body = await factory();
            // RequestOptions.copyWith treats null as retaining the old body.
            if (body == null && options.data != null) {
              throw StateError('Retry factory must provide a fresh body.');
            }
            if ((body is Stream || body is FormData) &&
                identical(body, options.data)) {
              throw StateError(
                'Retry factory returned the consumed request body.',
              );
            }
            if (body is FormData && body.isFinalized)
              throw StateError('Retry body is finalized.');
          } else if (options.extra[_replayKey] == true) {
            body = _copyBody(options.extra[_bodyKey]);
          } else {
            throw StateError(
              'Request body is not replayable; supply retryBodyFactory.',
            );
          }
          final current = await storage.getAccessToken();
          final token =
              current != null &&
                  current.isNotEmpty &&
                  current != options.extra[_tokenKey]
              ? current
              : await _refresh(revision);
          if (_disposed ||
              revision != storage.sessionRevision ||
              options.cancelToken?.isCancelled == true) {
            handler.next(error);
            return;
          }
          final retry = options.copyWith(
            data: body,
            headers: {...options.headers, 'Authorization': 'Bearer $token'},
            extra: {...options.extra, 'authRetried': true},
          );
          handler.resolve(await dio.fetch<dynamic>(retry));
        } on DioException catch (retryError) {
          handler.reject(retryError);
        } catch (failure) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: error.response,
              type: error.type,
              error: failure,
            ),
          );
        }
      },
    );
    dio.interceptors.add(_interceptor);
  }
  static const _revisionKey = 'event.auth.revision';
  static const _tokenKey = 'event.auth.usedToken';
  static const _bodyKey = 'event.auth.retryBody';
  static const _replayKey = 'event.auth.replayable';
  final Dio dio;
  final SecureStorageService storage;

  /// Must use a separate, non-auth-intercepted transport.
  final RefreshTokens refreshTokens;
  final FutureOr<void> Function() onSessionExpired;
  late final Interceptor _interceptor;
  Future<String>? _refreshing;
  int? _refreshRevision;
  int? _failedRevision;
  bool _disposed = false;

  static Object? _copyBody(Object? value) {
    if (value == null || value is String || value is num || value is bool)
      return value;
    if (value is List<int>) return List<int>.from(value);
    if (value is List) return value.map(_copyBody).toList();
    if (value is Map<String, dynamic>) {
      return value.map((key, item) => MapEntry(key, _copyBody(item)));
    }
    // Streams, FormData and custom encoders have no implicit safe replay contract.
    throw StateError('Unsupported retry body.');
  }

  Future<String> _refresh(int revision) {
    if (_refreshing != null && _refreshRevision == revision)
      return _refreshing!;
    if (revision == _failedRevision || revision != storage.sessionRevision) {
      return Future.error(StateError('Session is expired.'));
    }
    _refreshRevision = revision;
    final future = _performRefresh(revision);
    _refreshing = future;
    return future;
  }

  Future<String> _performRefresh(int revision) async {
    try {
      final refresh = await storage.getRefreshToken();
      if (_disposed || revision != storage.sessionRevision)
        throw StateError('Session changed.');
      if (refresh == null || refresh.isEmpty)
        throw StateError('No refresh token.');
      final tokens = await refreshTokens(refresh);
      if (tokens.accessToken.trim().isEmpty ||
          tokens.refreshToken.trim().isEmpty) {
        throw StateError('Invalid refreshed tokens.');
      }
      return await storage.withSessionLock(() async {
        if (_disposed || revision != storage.sessionRevision)
          throw StateError('Session changed.');
        await storage.saveAccessToken(tokens.accessToken);
        await storage.saveRefreshToken(tokens.refreshToken);
        if (_disposed || revision != storage.sessionRevision)
          throw StateError('Session changed.');
        return tokens.accessToken;
      });
    } catch (_) {
      int? expiredRevision;
      try {
        await storage.withSessionLock(() async {
          if (!_disposed &&
              revision == storage.sessionRevision &&
              _failedRevision != revision) {
            _failedRevision = revision;
            storage.invalidateSession();
            expiredRevision = storage.sessionRevision;
            await storage.clearAll();
          }
        });
      } finally {
        if (!_disposed &&
            expiredRevision != null &&
            expiredRevision == storage.sessionRevision) {
          await onSessionExpired();
        }
      }
      rethrow;
    } finally {
      if (_refreshRevision == revision) {
        _refreshing = null;
        _refreshRevision = null;
      }
    }
  }

  /// The injected Dio remains owned by its caller.
  void dispose() {
    _disposed = true;
    dio.interceptors.remove(_interceptor);
  }
}
