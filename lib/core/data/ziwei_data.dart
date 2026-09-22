import 'dart:convert';

import 'package:flutter/services.dart';

class ZiweiPalaceDefinition {
  const ZiweiPalaceDefinition({
    required this.id,
    required this.name,
    required this.topics,
    required this.boundary,
  });
  final String id;
  final String name;
  final List<String> topics;
  final String boundary;
}

class ZiweiStarDefinition {
  const ZiweiStarDefinition({
    required this.id,
    required this.name,
    required this.group,
    required this.yinYang,
    required this.element,
    required this.keywords,
  });
  final String id;
  final String name;
  final String group;
  final String yinYang;
  final String element;
  final List<String> keywords;
}

class ZiweiBrightnessData {
  const ZiweiBrightnessData({
    required this.profileId,
    required this.levels,
    required this.byStar,
    required this.sourceCommit,
  });

  final String profileId;
  final List<String> levels;
  final Map<String, Map<String, String?>> byStar;
  final String sourceCommit;

  String? lookup(String starName, String branch) => byStar[starName]?[branch];
}

abstract final class ZiweiData {
  static const _root = 'assets/data/ziwei';
  static List<ZiweiPalaceDefinition>? _palaces;
  static List<ZiweiStarDefinition>? _stars;
  static Map<String, List<String>>? _mutagens;
  static ZiweiBrightnessData? _brightness;

  static Future<List<ZiweiPalaceDefinition>> loadPalaces() async {
    if (_palaces != null) return _palaces!;
    final data = await _object('$_root/palaces.json');
    final rows = data['palaces'] as List? ?? const [];
    return _palaces = rows
        .whereType<Map>()
        .map((raw) {
          final map = Map<String, dynamic>.from(raw);
          return ZiweiPalaceDefinition(
            id: map['id'] as String,
            name: map['name'] as String,
            topics: (map['topics'] as List).whereType<String>().toList(
              growable: false,
            ),
            boundary: map['boundary'] as String,
          );
        })
        .toList(growable: false);
  }

  static Future<List<ZiweiStarDefinition>> loadStars() async {
    if (_stars != null) return _stars!;
    final data = await _object('$_root/stars.json');
    final rows = data['stars'] as List? ?? const [];
    return _stars = rows
        .whereType<Map>()
        .map((raw) {
          final map = Map<String, dynamic>.from(raw);
          return ZiweiStarDefinition(
            id: map['id'] as String,
            name: map['name'] as String,
            group: map['group'] as String,
            yinYang: map['yinYang'] as String,
            element: map['element'] as String,
            keywords: (map['keywords'] as List).whereType<String>().toList(
              growable: false,
            ),
          );
        })
        .toList(growable: false);
  }

  static Future<Map<String, List<String>>> loadMutagens() async {
    if (_mutagens != null) return _mutagens!;
    final data = await _object('$_root/mutagens.json');
    final raw = Map<String, dynamic>.from(data['byStem'] as Map);
    return _mutagens = Map.unmodifiable(
      raw.map(
        (key, value) => MapEntry(
          key,
          (value as List).whereType<String>().toList(growable: false),
        ),
      ),
    );
  }

  static Future<ZiweiBrightnessData> loadBrightness() async {
    if (_brightness != null) return _brightness!;
    final data = await _object('$_root/brightness.json');
    final rawTable = Map<String, dynamic>.from(data['byStar'] as Map);
    final source = Map<String, dynamic>.from(data['source'] as Map);
    final byStar = <String, Map<String, String?>>{};
    for (final entry in rawTable.entries) {
      final rawRows = Map<String, dynamic>.from(entry.value as Map);
      final rows = <String, String?>{};
      for (final row in rawRows.entries) {
        rows[row.key] = row.value as String?;
      }
      byStar[entry.key] = Map<String, String?>.unmodifiable(rows);
    }
    return _brightness = ZiweiBrightnessData(
      profileId: data['profileId'] as String,
      levels: (data['levels'] as List).whereType<String>().toList(
        growable: false,
      ),
      byStar: Map<String, Map<String, String?>>.unmodifiable(byStar),
      sourceCommit: source['commit'] as String,
    );
  }

  static Future<Map<String, dynamic>> loadManifest() =>
      _object('$_root/manifest.json');

  static Future<Map<String, dynamic>> _object(String path) async {
    final decoded = jsonDecode(await rootBundle.loadString(path));
    if (decoded is! Map) throw FormatException('$path 顶层必须是对象');
    return Map<String, dynamic>.from(decoded);
  }

  static void resetForTest() {
    _palaces = null;
    _stars = null;
    _mutagens = null;
    _brightness = null;
  }
}
