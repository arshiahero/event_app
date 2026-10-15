import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureStore implements SecureStore {
  FlutterSecureStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class InMemorySecureStore implements SecureStore {
  final Map<String, String> _values = {};
  @override
  Future<String?> read(String key) async => _values[key];
  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}

abstract final class StorageKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const userId = 'user_id';
  static const selectedCity = 'selected_city';
  static const userPreferences = 'user_preferences';
  static const all = [
    accessToken,
    refreshToken,
    userId,
    selectedCity,
    userPreferences,
  ];
}

class SecureStorageService {
  SecureStorageService(this.store);
  final SecureStore store;
  int _sessionRevision = 0;
  Future<void> _sessionTail = Future<void>.value();
  int get sessionRevision => _sessionRevision;

  /// Invalidate pending auth/refresh results synchronously before logout waits.
  void invalidateSession() {
    _sessionRevision++;
  }

  /// Session writers must use this lock for multi-key commits and cleanup.
  /// The queue never carries an error into a later transaction.
  Future<T> withSessionLock<T>(Future<T> Function() operation) async {
    final previous = _sessionTail;
    final done = Completer<void>();
    _sessionTail = done.future;
    await previous;
    try {
      return await operation();
    } finally {
      done.complete();
    }
  }

  Future<void> saveAccessToken(String value) =>
      store.write(StorageKeys.accessToken, value);
  Future<String?> getAccessToken() => store.read(StorageKeys.accessToken);
  Future<void> saveRefreshToken(String value) =>
      store.write(StorageKeys.refreshToken, value);
  Future<String?> getRefreshToken() => store.read(StorageKeys.refreshToken);
  Future<void> saveUserId(String value) =>
      store.write(StorageKeys.userId, value);
  Future<String?> getUserId() => store.read(StorageKeys.userId);
  Future<void> saveSelectedCity(String value) =>
      store.write(StorageKeys.selectedCity, value);
  Future<String?> getSelectedCity() => store.read(StorageKeys.selectedCity);
  Future<void> saveUserPreferences(Map<String, dynamic> value) =>
      store.write(StorageKeys.userPreferences, jsonEncode(value));
  Future<Map<String, dynamic>?> getUserPreferences() async {
    final value = await store.read(StorageKeys.userPreferences);
    return value == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(value) as Map);
  }

  Future<void> delete(String key) {
    if (!StorageKeys.all.contains(key)) throw ArgumentError.value(key, 'key');
    return store.delete(key);
  }

  /// Clear only this application's owned keys, not unrelated secure secrets.
  Future<void> clearAll() async {
    Object? firstError;
    StackTrace? firstStack;
    for (final key in StorageKeys.all) {
      try {
        await store.delete(key);
      } catch (error, stack) {
        firstError ??= error;
        firstStack ??= stack;
      }
    }
    if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
  }

  Future<bool> hasToken() async =>
      (await getAccessToken())?.trim().isNotEmpty ?? false;
}
