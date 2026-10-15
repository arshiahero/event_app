import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../storage/local_storage_service.dart';
import '../storage/secure_storage_service.dart';
import '../../features/auth/auth_models.dart';
import 'api_response.dart';
import 'auth_endpoints.dart';
import 'connectivity_service.dart';
import 'dio_client.dart';

final secureStoreProvider = Provider<SecureStore>(
  (ref) => ref.watch(appConfigProvider).useMocks
      ? InMemorySecureStore()
      : FlutterSecureStore(),
);
final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(ref.watch(secureStoreProvider)),
);

/// Real mode must override with SharedPreferencesStore after explicit initialization.
final localStoreProvider = Provider<LocalStore>((ref) {
  if (!ref.watch(appConfigProvider).useMocks) {
    throw StateError(
      'Override localStoreProvider with an initialized SharedPreferencesStore.',
    );
  }
  return InMemoryLocalStore();
});
final localStorageProvider = Provider<LocalStorageService>(
  (ref) => LocalStorageService(ref.watch(localStoreProvider)),
);

final authEndpointsProvider = Provider<AuthEndpoints>(
  (ref) => throw StateError(
    'Supply actual AuthEndpoints before using real authentication.',
  ),
);

/// Incremented on refresh failure; AuthController listens without a dependency cycle.
final sessionExpiredProvider = StateProvider<int>((ref) => 0);
final onSessionExpiredProvider = Provider<FutureOr<void> Function()>(
  (ref) => () {
    ref.read(sessionExpiredProvider.notifier).state++;
  },
);

Dio _newDio(String? baseUrl) => Dio(
  BaseOptions(
    baseUrl: baseUrl ?? '',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
  ),
);

/// No requests are performed by constructing this provider. Mock Dio rejects
/// requests locally, preventing accidental network access from mock consumers.
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = _newDio(config.apiBaseUri?.toString());
  if (config.useMocks) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: const NetworkFailure(
                NetworkFailureKind.offline,
                'Network is disabled in mock mode.',
              ),
            ),
          );
        },
      ),
    );
  }
  ref.onDispose(() => dio.close(force: true));
  return dio;
});

/// Separate, non-auth-intercepted transport prevents recursive refresh calls.
final refreshDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMocks)
    throw StateError('Refresh transport is unavailable in mock mode.');
  final dio = _newDio(config.apiBaseUri!.toString());
  ref.onDispose(() => dio.close(force: true));
  return dio;
});
final refreshTokensProvider = Provider<RefreshTokens>((ref) {
  final dio = ref.watch(refreshDioProvider);
  final endpoints = ref.watch(authEndpointsProvider);
  return (token) async {
    try {
      final response = await dio.post<dynamic>(
        endpoints.refresh,
        data: {'refresh_token': token},
      );
      return ApiResponse<AuthTokens>.fromJson(
        Map<String, dynamic>.from(response.data as Map),
        (data) => AuthTokens.fromJson(Map<String, dynamic>.from(data as Map)),
      ).data;
    } on DioException catch (error) {
      throw NetworkFailure.fromDio(error);
    } on FormatException {
      throw const NetworkFailure(NetworkFailureKind.invalidResponse, 'Invalid refresh response.');
    } on TypeError {
      throw const NetworkFailure(NetworkFailureKind.invalidResponse, 'Invalid refresh response.');
    }
  };
});
final dioClientProvider = Provider<DioClient>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMocks)
    throw StateError('Use mock repositories, not DioClient, in mock mode.');
  final client = DioClient(
    dio: ref.watch(dioProvider),
    storage: ref.watch(secureStorageProvider),
    refreshTokens: ref.watch(refreshTokensProvider),
    onSessionExpired: ref.watch(onSessionExpiredProvider),
    debugLogs: config.debugNetworkLogs,
  );
  ref.onDispose(client.dispose);
  return client;
});
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final mocks = ref.watch(appConfigProvider).useMocks;
  final service = ConnectivityService(
    useMocks: mocks,
    connectivity: mocks ? null : Connectivity(),
  );
  ref.onDispose(() {
    unawaited(service.dispose().catchError((Object _, StackTrace __) {
      if (kDebugMode) debugPrint('Connectivity shutdown failed [details redacted]');
    }));
  });
  return service;
});
