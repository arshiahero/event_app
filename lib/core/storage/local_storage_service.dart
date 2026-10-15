import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive preferences only; never store tokens or passwords here.
abstract interface class LocalStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SharedPreferencesStore implements LocalStore {
  SharedPreferencesStore(this.preferences);
  final SharedPreferences preferences;
  @override
  Future<String?> read(String key) async => preferences.getString(key);
  @override
  Future<void> write(String key, String value) async {
    if (!await preferences.setString(key, value))
      throw StateError('Preference write failed.');
  }

  @override
  Future<void> delete(String key) async {
    if (!await preferences.remove(key))
      throw StateError('Preference deletion failed.');
  }
}

class InMemoryLocalStore implements LocalStore {
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

class LocalStorageService {
  LocalStorageService(this.store);
  final LocalStore store;
  static const _city = 'event.selected_city';
  static const _preferences = 'event.preferences';
  static const _favorites = 'event.favorites';
  static const _tickets = 'event.tickets';
  Future<String?> getSelectedCity() => store.read(_city);
  Future<void> saveSelectedCity(String value) => store.write(_city, value);
  Future<void> savePreferences(Map<String, dynamic> value) =>
      store.write(_preferences, jsonEncode(value));
  Future<Map<String, dynamic>?> getPreferences() async {
    final raw = await store.read(_preferences);
    return raw == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> deleteSelectedCity() => store.delete(_city);
  Future<void> deletePreferences() => store.delete(_preferences);
  Future<void> clearAll() async {
    await deleteSelectedCity();
    await deletePreferences();
  }

  Future<void> saveFavorites(List<String> ids) =>
      store.write(_favorites, jsonEncode(ids));

  Future<List<String>?> getFavorites() async {
    final raw = await store.read(_favorites);
    if (raw == null) return null;
    return (jsonDecode(raw) as List).whereType<String>().toList();
  }

  Future<void> saveTickets(List<Map<String, dynamic>> tickets) =>
      store.write(_tickets, jsonEncode(tickets));

  Future<List<Map<String, dynamic>>?> getTickets() async {
    final raw = await store.read(_tickets);
    if (raw == null) return null;
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
