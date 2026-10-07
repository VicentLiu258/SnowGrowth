import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage._();

  static Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  static Future<String?> getString(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }

  static Future<int?> getInt(String key) async {
    final prefs = await _prefs;
    return prefs.getInt(key);
  }

  static Future<void> setInt(String key, int value) async {
    final prefs = await _prefs;
    await prefs.setInt(key, value);
  }

  static Future<double?> getDouble(String key) async {
    final prefs = await _prefs;
    return prefs.getDouble(key);
  }

  static Future<void> setDouble(String key, double value) async {
    final prefs = await _prefs;
    await prefs.setDouble(key, value);
  }

  static Future<void> remove(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }

  static Future<void> removeAll(List<String> keys) async {
    final prefs = await _prefs;
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  static Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  /// Calculator-related keys used by Settings "Clear Cache".
  static const List<String> calculatorCacheKeys = [
    'pct_mode',
    'pct_x',
    'pct_y',
    'tip_bill',
    'tip_pct',
    'tip_split',
    'unit_cat',
    'unit_from',
    'unit_to',
    'unit_v1',
    'unit_v2',
    'unit_last_edit',
  ];

  static Future<T> getJson<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
    T defaultValue,
  ) async {
    final raw = await getString(key);
    if (raw == null) return defaultValue;
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return defaultValue;
    }
  }

  static Future<void> setJson(String key, Map<String, dynamic> value) async {
    await setString(key, jsonEncode(value));
  }
}
