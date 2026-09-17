/// 卦象数据加载器
library;

import 'dart:convert';

import 'package:flutter/services.dart';

/// 八卦数据模型
class Trigram {
  final int index;
  final String name;
  final String symbol;
  final String nature;
  final String element;
  final List<int> lines;
  final String binary;

  const Trigram({
    required this.index,
    required this.name,
    required this.symbol,
    required this.nature,
    required this.element,
    required this.lines,
    required this.binary,
  });

  factory Trigram.fromJson(Map<String, dynamic> json) {
    return Trigram(
      index: json['index'] as int,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      nature: json['nature'] as String,
      element: json['element'] as String,
      lines: (json['lines'] as List).cast<int>(),
      binary: json['binary'] as String,
    );
  }
}

/// 六十四卦数据模型
class Hexagram {
  final int id;
  final String name;
  final String symbol;
  final String binary;
  final String upper;
  final String lower;
  final String palace;
  final String description;

  /// 六爻爻辞，顺序为初爻到上爻（自下而上）。
  final List<String> yaoCi;

  /// 乾卦用九、坤卦用六；其余卦为空。
  final String? yongCi;

  const Hexagram({
    required this.id,
    required this.name,
    required this.symbol,
    required this.binary,
    required this.upper,
    required this.lower,
    required this.palace,
    required this.description,
    required this.yaoCi,
    this.yongCi,
  });

  factory Hexagram.fromJson(Map<String, dynamic> json) {
    return Hexagram(
      id: json['id'] as int,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      binary: json['binary'] as String,
      upper: json['upper'] as String,
      lower: json['lower'] as String,
      palace: json['palace'] as String,
      description: json['description'] as String,
      yaoCi: (json['yaoCi'] as List).cast<String>(),
      yongCi: json['yongCi'] as String?,
    );
  }
}

/// 卦象数据加载器
class HexagramData {
  static List<Trigram>? _trigrams;
  static List<Hexagram>? _hexagrams;

  /// 加载卦象数据
  static Future<void> load() async {
    if (_trigrams != null && _hexagrams != null) return;

    // 加载八卦数据
    final trigramsJson = await rootBundle.loadString(
      'assets/data/trigrams.json',
    );
    final trigramsData = jsonDecode(trigramsJson) as Map<String, dynamic>;
    _trigrams = (trigramsData['trigrams'] as List)
        .map((e) => Trigram.fromJson(e as Map<String, dynamic>))
        .toList();

    // 加载六十四卦数据
    final hexagramsJson = await rootBundle.loadString(
      'assets/data/hexagrams.json',
    );
    final hexagramsData = jsonDecode(hexagramsJson) as Map<String, dynamic>;
    _hexagrams = (hexagramsData['hexagrams'] as List)
        .map((e) => Hexagram.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取所有八卦
  static List<Trigram> get trigrams {
    if (_trigrams == null) {
      throw StateError(
        'HexagramData not loaded. Call HexagramData.load() first.',
      );
    }
    return _trigrams!;
  }

  /// 获取所有六十四卦
  static List<Hexagram> get hexagrams {
    if (_hexagrams == null) {
      throw StateError(
        'HexagramData not loaded. Call HexagramData.load() first.',
      );
    }
    return _hexagrams!;
  }

  /// 根据索引获取八卦
  static Trigram? getTrigramByIndex(int index) {
    for (final trigram in trigrams) {
      if (trigram.index == index) return trigram;
    }
    return null;
  }

  /// 根据名称获取八卦
  static Trigram? getTrigramByName(String name) {
    for (final trigram in trigrams) {
      if (trigram.name == name) return trigram;
    }
    return null;
  }

  /// 根据ID获取六十四卦
  static Hexagram? getHexagramById(int id) {
    for (final hexagram in hexagrams) {
      if (hexagram.id == id) return hexagram;
    }
    return null;
  }

  /// 根据名称获取六十四卦
  static Hexagram? getHexagramByName(String name) {
    for (final hexagram in hexagrams) {
      if (hexagram.name == name) return hexagram;
    }
    return null;
  }

  /// 根据六位卦象查找。格式为上卦三位 + 下卦三位，
  /// 每组三位内部均按初爻到三爻（自下而上）排列。
  static Hexagram? getHexagramByBinary(String binary) {
    for (final hexagram in hexagrams) {
      if (hexagram.binary == binary) return hexagram;
    }
    return null;
  }

  /// 根据宫位获取六十四卦
  static List<Hexagram> getHexagramsByPalace(String palace) {
    return hexagrams.where((h) => h.palace == palace).toList();
  }
}
