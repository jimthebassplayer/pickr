import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/season.dart';
import '../data/teams.dart';

const String picksPrefsKey = 'survivor_picks_v1';

abstract class PickStore {
  Future<Map<int, String>> load();
  Future<void> save(Map<int, String> picks);
}

class SharedPreferencesPickStore implements PickStore {
  @override
  Future<Map<int, String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return decodePicks(prefs.getString(picksPrefsKey));
  }

  @override
  Future<void> save(Map<int, String> picks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(picksPrefsKey, encodePicks(picks));
  }
}

class MemoryPickStore implements PickStore {
  MemoryPickStore([Map<int, String>? initial])
    : _picks = Map<int, String>.of(initial ?? {});

  Map<int, String> _picks;

  @override
  Future<Map<int, String>> load() async => Map<int, String>.of(_picks);

  @override
  Future<void> save(Map<int, String> picks) async {
    _picks = Map<int, String>.of(picks);
  }
}

String encodePicks(Map<int, String> picks) {
  return jsonEncode({
    for (final entry in picks.entries) '${entry.key}': entry.value,
  });
}

Map<int, String> decodePicks(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    final picks = <int, String>{};
    for (final entry in decoded.entries) {
      final week = int.tryParse(entry.key.toString());
      final team = entry.value;
      if (week == null || week < 1 || week > seasonWeeks) continue;
      if (team is! String || !teamNicknames.containsKey(team)) continue;
      picks[week] = team;
    }
    return picks;
  } on FormatException {
    return {};
  }
}
