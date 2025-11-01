import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized cache keys for consistent cache management
class CacheKeys {
  CacheKeys._(); // Private constructor
  
  // Team-related cache keys
  static const String teams = 'teams_cache';
  
  // Player-related cache keys
  static String roster(String teamId) => 'roster_cache_$teamId';
  static String player(String playerId) => 'player_$playerId';
  
  // Game-related cache keys
  static String games(String teamId) => 'games_cache_$teamId';
  static String game(String gameId) => 'game_$gameId';
  
  // AtBat-related cache keys
  static String atBats(String gameId) => 'atbats_cache_$gameId';
  static String atBat(String atBatId) => 'atbat_$atBatId';
  
  // User-related cache keys
  static const String currentUser = 'current_user_cache';
  static const String userContext = 'user_context_cache';
}

class Persistence {
  // Increment this when cache format changes or to force cache clear
  static const int cacheVersion = 2;
  static const String _versionKey = 'cache_version';
  
  // Default TTL (24 hours)
  static const Duration defaultTTL = Duration(hours: 24);
  
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

  /// Set JSON data with optional TTL
  /// 
  /// [key] - Cache key
  /// [value] - Data to cache (will be JSON encoded)
  /// [ttl] - Optional time-to-live. If null, uses defaultTTL (24 hours)
  static Future<void> setJson(String key, Object value, {Duration? ttl}) async {
    final prefs = await _prefs();
    final cacheData = {
      'version': cacheVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'ttl': (ttl ?? defaultTTL).inSeconds,
      'data': value,
    };
    final encoded = jsonEncode(cacheData);
    await prefs.setString(key, encoded);
  }

  /// Get JSON data with TTL checking
  /// 
  /// Returns null if:
  /// - Cache doesn't exist
  /// - Cache version mismatch
  /// - Cache is expired (beyond TTL)
  /// - JSON decode fails
  static Future<T?> getJson<T>(String key, T Function(Object?) map, {bool checkTTL = true}) async {
    final prefs = await _prefs();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    
    try {
      final cacheData = jsonDecode(raw) as Map<String, dynamic>;
      
      // Check version
      final version = cacheData['version'] as int?;
      if (version != cacheVersion) {
        await prefs.remove(key);
        return null;
      }
      
      // Check TTL if enabled
      if (checkTTL) {
        final timestampStr = cacheData['timestamp'] as String?;
        final ttlSeconds = cacheData['ttl'] as int?;
        
        if (timestampStr != null && ttlSeconds != null) {
          final timestamp = DateTime.parse(timestampStr);
          final ttl = Duration(seconds: ttlSeconds);
          
          if (DateTime.now().difference(timestamp) > ttl) {
            // Cache expired
            await prefs.remove(key);
            return null;
          }
        }
      }
      
      // Extract and map data
      final data = cacheData['data'];
      return map(data);
    } catch (_) {
      // Clear corrupted cache
      await prefs.remove(key);
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
  
  /// Clear a specific cache key
  static Future<void> clear(String key) async {
    final prefs = await _prefs();
    await prefs.remove(key);
  }
}


