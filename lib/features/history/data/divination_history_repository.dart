import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/algorithm.dart';
import 'package:zhaoxingzhai/features/tarot/tarot_divination.dart';

class DivinationHistoryRecord {
  final String id;
  final String type;
  final String title;
  final String summary;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  const DivinationHistoryRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.summary,
    required this.createdAt,
    required this.payload,
  });

  String get typeLabel => switch (type) {
    'xiaoliuren' => '小六壬',
    'tarot' => '塔罗',
    _ => type,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'summary': summary,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'payload': payload,
  };

  factory DivinationHistoryRecord.fromJson(Map<String, dynamic> json) {
    return DivinationHistoryRecord(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
    );
  }
}

class DivinationHistoryRepository extends ChangeNotifier {
  static const _storageKey = 'zhaoxingzhai.divination_history.v1';
  static const _maxRecords = 100;

  final Future<SharedPreferences> Function() _preferencesFactory;
  final List<DivinationHistoryRecord> _records = [];
  Future<void>? _loadFuture;
  bool _isLoaded = false;
  String? _loadError;

  DivinationHistoryRepository({
    Future<SharedPreferences> Function()? preferencesFactory,
  }) : _preferencesFactory =
           preferencesFactory ?? SharedPreferences.getInstance;

  List<DivinationHistoryRecord> get records => List.unmodifiable(_records);
  bool get isLoaded => _isLoaded;
  String? get loadError => _loadError;

  Future<void> ensureLoaded() => _loadFuture ??= _load();

  Future<void> _load() async {
    try {
      final preferences = await _preferencesFactory();
      final raw = preferences.getString(_storageKey);
      _records.clear();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is! List) {
          throw const FormatException('历史记录格式无效');
        }
        for (final item in decoded) {
          try {
            _records.add(
              DivinationHistoryRecord.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            );
          } catch (_) {
            // 单条旧数据损坏时保留其余可读记录。
          }
        }
        _records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      _loadError = null;
    } catch (error) {
      _loadError = error.toString();
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> addTarot(TarotDrawResult result) async {
    final previewCards = result.cards
        .take(3)
        .map((card) => '${card.position}：${card.name}${card.orientation}');
    final remaining = result.cards.length - 3;
    final summary = [
      ...previewCards,
      if (remaining > 0) '另有 $remaining 张牌',
    ].join('；');

    await add(
      DivinationHistoryRecord(
        id: 'tarot:${result.timestamp.microsecondsSinceEpoch}',
        type: 'tarot',
        title: result.spreadName,
        summary: summary,
        createdAt: result.timestamp,
        payload: {
          'spreadType': result.spreadType,
          'spreadName': result.spreadName,
          'cards': result.cards
              .map(
                (card) => {
                  'cardId': card.cardId,
                  'position': card.position,
                  'name': card.name,
                  'orientation': card.orientation,
                  'keywords': card.keywords,
                  'element': card.element,
                  'archetype': card.archetype,
                },
              )
              .toList(),
          'evidencePrompt': result.evidenceAnalysis.promptText,
          if (result.randomTrace != null)
            'randomTrace': result.randomTrace!.toJson(),
        },
      ),
    );
  }

  Future<void> addXiaoliuren(XiaoliurenData result) async {
    await add(
      DivinationHistoryRecord(
        id: result.meta.resultId,
        type: 'xiaoliuren',
        title: '${result.primary.name} · ${result.ruleLabel}',
        summary:
            '${result.timestamp.year}-${result.timestamp.month.toString().padLeft(2, '0')}-'
            '${result.timestamp.day.toString().padLeft(2, '0')} ${result.hourLabel}；'
            '月宫 ${result.sequence['month']!.name}，'
            '日宫 ${result.sequence['day']!.name}，'
            '时宫 ${result.sequence['hour']!.name}',
        createdAt: result.meta.calculatedAt.toLocal(),
        payload: result.toJson(),
      ),
    );
  }

  Future<void> add(DivinationHistoryRecord record) async {
    await ensureLoaded();
    _records.removeWhere((item) => item.id == record.id);
    _records.insert(0, record);
    if (_records.length > _maxRecords) {
      _records.removeRange(_maxRecords, _records.length);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await ensureLoaded();
    _records.removeWhere((record) => record.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> clear() async {
    await ensureLoaded();
    _records.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final preferences = await _preferencesFactory();
    final encoded = jsonEncode(
      _records.map((record) => record.toJson()).toList(),
    );
    final saved = await preferences.setString(_storageKey, encoded);
    if (!saved) {
      throw StateError('本地历史记录写入失败');
    }
  }
}
