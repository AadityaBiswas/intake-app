import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food.dart';

class FoodCacheService {
  static const String _foodsCacheKey = 'cached_frequent_foods';

  /// How many foods to keep in the local cache
  static const int _maxCachedFoods = 50;

  /// Static in-memory cache shared across all instances.
  /// Avoids repeated SharedPreferences disk reads.
  static List<Map<String, dynamic>>? _memoryCache;

  /// Loads the cached foods, using in-memory cache when available.
  Future<List<Map<String, dynamic>>> _loadCache() async {
    if (_memoryCache != null) return _memoryCache!;

    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_foodsCacheKey);
    if (jsonStr == null) {
      _memoryCache = [];
      return _memoryCache!;
    }

    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      _memoryCache = decoded.cast<Map<String, dynamic>>();
      return _memoryCache!;
    } catch (e) {
      _memoryCache = [];
      return _memoryCache!;
    }
  }

  /// Saves the cache list back to SharedPreferences and updates memory cache.
  Future<void> _saveCache(List<Map<String, dynamic>> cache) async {
    // Encode FIRST — if this throws, _memoryCache stays untouched.
    final encoded = json.encode(cache);
    _memoryCache = cache;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_foodsCacheKey, encoded);
  }

  /// Pre-loads the cache into memory so subsequent reads are instant.
  Future<void> preWarm() async {
    await _loadCache();
  }

  /// Creates a JSON-safe copy of the food data for local storage.
  /// Strips FieldValue sentinels (e.g. serverTimestamp) that can't be
  /// encoded to JSON.
  Map<String, dynamic> _toJsonSafe(Food food) {
    final map = food.toFirestore();
    map.remove('created_at');
    return map;
  }

  /// Increments the usage count of a food item in the cache.
  /// Never throws — cache errors are silently swallowed so the food
  /// resolution pipeline is never blocked.
  Future<void> incrementFood(Food food) async {
    try {
      // Work on a COPY so in-place mutations can't corrupt _memoryCache.
      final original = await _loadCache();
      final cache = original.map((e) => Map<String, dynamic>.from(e)).toList();

      // Find if it already exists
      int index = cache.indexWhere((item) => item['id'] == food.id);

      if (index >= 0) {
        // Item exists, increment count
        cache[index]['count'] = (cache[index]['count'] as int) + 1;
        // Also update the food data in case it changed (eg nutrition refined)
        cache[index]['food'] = _toJsonSafe(food);
      } else {
        // New item
        cache.add({
          'id': food.id,
          'count': 1,
          'food': _toJsonSafe(food),
        });
      }

      // Sort by descending count
      cache.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      // Truncate to max size
      if (cache.length > _maxCachedFoods) {
        cache.removeRange(_maxCachedFoods, cache.length);
      }

      await _saveCache(cache);
    } catch (e) {
      // Reset in-memory cache so next call reloads clean data from disk.
      _memoryCache = null;
      debugPrint('FoodCacheService.incrementFood failed (non-fatal): $e');
    }
  }

  /// Returns cached foods matching the prefix, up to a limit.
  /// Never throws — returns empty list on any error so the caller
  /// can fall back to Firestore.
  Future<List<Food>> getTopFoods(String prefix, {int limit = 5}) async {
    final cleanPrefix = prefix.toLowerCase().trim();
    if (cleanPrefix.isEmpty) return [];

    try {
      final cache = await _loadCache();
      final List<Food> results = [];

      for (var item in cache) {
        final foodMap = item['food'] as Map<String, dynamic>;

        // We pass the stored id as well since toFirestore doesn't always contain the document ID
        final food = Food.fromFirestore(foodMap, item['id'] as String);

        if (food.nameLowercase.startsWith(cleanPrefix) ||
            food.searchKeywords.any((k) => k.startsWith(cleanPrefix))) {
          results.add(food);
          if (results.length >= limit) break;
        }
      }

      return results;
    } catch (e) {
      debugPrint('FoodCacheService.getTopFoods failed (non-fatal): $e');
      return [];
    }
  }
}
