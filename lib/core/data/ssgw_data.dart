import 'dart:convert';

import 'package:flutter/services.dart';

class SsgwSign {
  const SsgwSign({
    required this.number,
    required this.title,
    required this.poem,
    required this.story,
    required this.details,
  });

  final int number;
  final String title;
  final String poem;
  final String story;
  final Map<String, String> details;

  factory SsgwSign.fromJson(Map<String, dynamic> json) => SsgwSign(
    number: json['id'] as int,
    title: json['title'] as String,
    poem: json['qianwen'] as String,
    story: json['story'] as String,
    details: Map<String, String>.from(json['details'] as Map),
  );

  Map<String, dynamic> toJson() => {
    'number': number,
    'title': title,
    'poem': poem,
    'story': story,
    'details': details,
  };
}

abstract final class SsgwData {
  static List<SsgwSign>? _signs;

  static Future<void> load() async {
    if (_signs != null) return;
    final source = await rootBundle.loadString('assets/data/ssgw.json');
    final json = jsonDecode(source) as Map<String, dynamic>;
    final signs = (json['signs'] as List)
        .map(
          (item) => SsgwSign.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
    if (signs.length != 92) {
      throw const FormatException('三山国王灵签数据必须包含 92 签');
    }
    _signs = signs;
  }

  static List<SsgwSign> get signs {
    final value = _signs;
    if (value == null) throw StateError('SsgwData not loaded.');
    return value;
  }

  static SsgwSign? getByNumber(int number) {
    if (number < 1 || number > signs.length) return null;
    final sign = signs[number - 1];
    if (sign.number == number) return sign;
    for (final item in signs) {
      if (item.number == number) return item;
    }
    return null;
  }
}
