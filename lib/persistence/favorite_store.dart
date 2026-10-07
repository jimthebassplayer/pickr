import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/teams.dart';

const String favoritesPrefsKey = 'survivor_favorites_v1';

/// Teams the user wants kept in view. Not the side favored to win.
abstract class FavoriteStore {
  Future<Set<String>> load();
  Future<void> save(Set<String> teams);
}

class SharedPreferencesFavoriteStore implements FavoriteStore {
  @override
  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return decodeFavorites(prefs.getString(favoritesPrefsKey));
  }

  @override
  Future<void> save(Set<String> teams) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(favoritesPrefsKey, encodeFavorites(teams));
  }
}

class MemoryFavoriteStore implements FavoriteStore {
  MemoryFavoriteStore([Set<String>? initial])
    : _teams = Set<String>.of(initial ?? {});

  Set<String> _teams;

  @override
  Future<Set<String>> load() async => Set<String>.of(_teams);

  @override
  Future<void> save(Set<String> teams) async {
    _teams = Set<String>.of(teams);
  }
}

String encodeFavorites(Set<String> teams) {
  final codes = teams.toList()..sort();
  return jsonEncode(codes);
}

Set<String> decodeFavorites(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return {};
    return {
      for (final code in decoded)
        if (code is String && teamNicknames.containsKey(code)) code,
    };
  } on FormatException {
    return {};
  }
}
