import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteManager {
  static const String _key = 'favorites';

  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_key) ?? [];

    List<Map<String, dynamic>> validFavorites = [];

    for (final item in favorites) {
      try {
        final decoded = json.decode(item);
        if (decoded is Map<String, dynamic>) {
          validFavorites.add(decoded);
        } else if (decoded is Map) {
          validFavorites.add(Map<String, dynamic>.from(decoded));
        }
      } catch (e) {
        print("Error decoding favorite: $e\nInvalid data: $item");
        // Optionally: remove or clean the bad item from SharedPreferences
      }
    }

    return validFavorites;
  }




  static Future<bool> isFavorite(int recipeId) async {
    final favorites = await getFavorites();
    return favorites.any((item) => item['id'] == recipeId);
  }

  static Future<void> addFavorite(Map<String, dynamic> recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_key) ?? [];

    final exists = favorites.any((item) {
      try {
        final decoded = json.decode(item);
        return decoded['id'] == recipe['id'];
      } catch (_) {
        return false;
      }
    });

    if (!exists) {
      favorites.add(json.encode(recipe));
      await prefs.setStringList(_key, favorites);
    }
  }

  static Future<void> removeFavorite(int recipeId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_key) ?? [];

    favorites.removeWhere((item) {
      try {
        final decoded = json.decode(item);
        return decoded['id'] == recipeId;
      } catch (_) {
        return false;
      }
    });

    await prefs.setStringList(_key, favorites);
  }
}
