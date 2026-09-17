import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/algorithm.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/shared/result.dart';
import 'package:zhaoxingzhai/features/tarot/tarot_divination.dart';

/// 一条占卜历史记录。
///
/// [caseSnapshot] 保存的是计算当时的案例副本，不是当前案例的引用：
/// 修改或删除案例不得改变已存在的历史。
///
/// [algorithmId] / [algorithmVersion] / [schemaVersion] 提升到顶层，
/// 是为了让旧数据可被查询、比对和迁移；它们同时仍保留在 [payload] 中，
/// 以便按原始结果结构复查。
class DivinationHistoryRecord {
  final String id;
  final String type;
  final String title;
  final String summary;
  final DateTime createdAt;
  final Map<String, dynamic> payload;
  final String algorithmId;
  final int algorithmVersion;
  final String schemaVersion;

  /// 计算当时的案例副本；无主体的一次性占卜为 `null`。
  final CaseSnapshot? caseSnapshot;

  const DivinationHistoryRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.summary,
    required this.createdAt,
    required this.payload,
    required this.algorithmId,
    required this.algorithmVersion,
    required this.schemaVersion,
    this.caseSnapshot,
  });

  String get typeLabel => switch (type) {
    'xiaoliuren' => '小六壬',
    'tarot' => '塔罗',
    _ => type,
  };

  /// 算法身份，用于判断旧结果能否被当前实现 replay。
  String get algorithmLabel => '$algorithmId v$algorithmVersion';

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'summary': summary,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'payload': payload,
    'algorithmId': algorithmId,
    'algorithmVersion': algorithmVersion,
    'schemaVersion': schemaVersion,
    if (caseSnapshot != null) 'caseSnapshot': caseSnapshot!.toJson(),
  };

  factory DivinationHistoryRecord.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] is Map
        ? Map<String, dynamic>.from(json['payload'] as Map)
        : <String, dynamic>{};

    // 早期记录没有顶层版本字段，回落到 payload 内的结果元数据；
    // 两者都没有时按 v0 处理，明确标记为「未知版本」而不是假装是 v1。
    final meta = payload['meta'];
    final metaMap = meta is Map
        ? Map<String, dynamic>.from(meta)
        : const <String, dynamic>{};
    final algorithm = payload['algorithm'];
    final algorithmMap = algorithm is Map
        ? Map<String, dynamic>.from(algorithm)
        : const <String, dynamic>{};
    final fallback = <String, dynamic>{
      ...metaMap,
      ...algorithmMap,
      ...payload,
    };

    final snapshotRaw = json['caseSnapshot'];
    final snapshot = snapshotRaw is Map
        ? CaseSnapshot.fromJson(Map<String, dynamic>.from(snapshotRaw))
        : null;

    return DivinationHistoryRecord(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      payload: payload,
      algorithmId:
          json['algorithmId'] as String? ?? fallback['algorithm'] as String? ?? 'unknown',
      algorithmVersion: (json['algorithmVersion'] as num?)?.toInt() ??
          (fallback['algorithmVersion'] as num?)?.toInt() ??
          0,
      schemaVersion: json['schemaVersion'] as String? ??
          fallback['schemaVersion'] as String? ??
          'unknown',
      caseSnapshot: snapshot,
    );
  }
}

class DivinationHistoryRepository extends ChangeNotifier {
  static const String storageKey = 'zhaoxingzhai.divination_history.v1';
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
      final raw = preferences.getString(storageKey);
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

  Future<void> addTarot(
    TarotDrawResult result, {
    CaseSnapshot? caseSnapshot,
  }) async {
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
        algorithmId: result.algorithm.id,
        algorithmVersion: result.algorithm.version,
        schemaVersion: mingyuSchemaVersion,
        caseSnapshot: caseSnapshot,
        payload: {
          'algorithm': result.algorithm.toJson(),
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

  Future<void> addXiaoliuren(
    XiaoliurenData result, {
    CaseSnapshot? caseSnapshot,
  }) async {
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
        algorithmId: result.meta.algorithm,
        algorithmVersion: result.meta.algorithmVersion,
        schemaVersion: result.meta.schemaVersion,
        caseSnapshot: caseSnapshot,
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
    final saved = await preferences.setString(storageKey, encoded);
    if (!saved) {
      throw StateError('本地历史记录写入失败');
    }
  }
}
