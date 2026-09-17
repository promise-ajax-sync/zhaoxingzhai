/// 塔罗牌数据加载器
library;

import 'dart:convert';

import 'package:flutter/services.dart';

/// 塔罗牌数据模型
class TarotCard {
  final String name;
  final String type;
  final int number;
  final String? suit;

  const TarotCard({
    required this.name,
    required this.type,
    required this.number,
    this.suit,
  });

  factory TarotCard.fromJson(Map<String, dynamic> json) {
    return TarotCard(
      name: json['name'] as String,
      type: json['type'] as String,
      number: json['number'] as int,
      suit: json['suit'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'number': number,
      if (suit != null) 'suit': suit,
    };
  }
}

/// 塔罗牌阵数据模型
class TarotSpread {
  final String name;
  final String description;
  final List<String> positions;
  final int cardCount;

  const TarotSpread({
    required this.name,
    required this.description,
    required this.positions,
    required this.cardCount,
  });

  factory TarotSpread.fromJson(Map<String, dynamic> json) {
    return TarotSpread(
      name: json['name'] as String,
      description: json['description'] as String,
      positions: (json['positions'] as List).cast<String>(),
      cardCount: json['cardCount'] as int,
    );
  }
}

/// 塔罗牌数据加载器
class TarotData {
  static List<TarotCard>? _cards;
  static Map<String, TarotSpread>? _spreads;

  /// 加载塔罗牌数据
  static Future<void> load() async {
    if (_cards != null && _spreads != null) return;

    final jsonString = await rootBundle.loadString('assets/data/tarot.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    _cards = (json['cards'] as List)
        .map((e) => TarotCard.fromJson(e as Map<String, dynamic>))
        .toList();

    final spreadsJson = json['spreads'] as Map<String, dynamic>;
    _spreads = spreadsJson.map(
      (key, value) =>
          MapEntry(key, TarotSpread.fromJson(value as Map<String, dynamic>)),
    );
  }

  /// 获取所有塔罗牌
  static List<TarotCard> get cards {
    if (_cards == null) {
      throw StateError('TarotData not loaded. Call TarotData.load() first.');
    }
    return _cards!;
  }

  /// 获取所有牌阵
  static Map<String, TarotSpread> get spreads {
    if (_spreads == null) {
      throw StateError('TarotData not loaded. Call TarotData.load() first.');
    }
    return _spreads!;
  }

  /// 根据编号获取塔罗牌
  static TarotCard? getCardByNumber(int number) {
    for (final card in cards) {
      if (card.number == number) return card;
    }
    return null;
  }

  /// 获取大阿卡纳牌
  static List<TarotCard> get majorArcana {
    return cards.where((card) => card.type == '大阿卡纳').toList();
  }

  /// 获取小阿卡纳牌
  static List<TarotCard> get minorArcana {
    return cards.where((card) => card.type == '小阿卡纳').toList();
  }

  /// 根据花色获取小阿卡纳牌
  static List<TarotCard> getCardsBySuit(String suit) {
    return cards.where((card) => card.suit == suit).toList();
  }
}
