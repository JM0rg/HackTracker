import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Persistence {
  // Increment this when cache format changes or to force cache clear
  static const int cacheVersion = 2;
  static const String _versionKey = 'cache_version';
  
  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  /// Check and clear cache if version mismatch
  static Future<void> checkCacheVersion() async {
    final prefs = await _prefs();
    final storedVersion = prefs.getInt(_versionKey);
    
    if (storedVersion != cacheVersion) {
      // Clear all cache on version mismatch
      await prefs.clear();
      await prefs.setInt(_versionKey, cacheVersion);
    }
  }

  static Future<void> setJson(String key, Object value) async {
    final prefs = await _prefs();
    final encoded = jsonEncode(value);
    await prefs.setString(key, encoded);
  }

  static Future<T?> getJson<T>(String key, T Function(Object?) map) async {
    final prefs = await _prefs();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return map(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> remove(String key) async {
    final prefs = await _prefs();
    await prefs.remove(key);
  }
  
  static Future<void> clearAll() async {
    final prefs = await _prefs();
    await prefs.clear();
    await prefs.setInt(_versionKey, cacheVersion);
  }
}


