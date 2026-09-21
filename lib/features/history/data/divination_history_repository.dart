import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/database/app_database.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/algorithm.dart';
import 'package:zhaoxingzhai/core/engine/daily_hexagram/daily_hexagram.dart';
import 'package:zhaoxingzhai/core/engine/meihua/meihua_divination.dart';
import 'package:zhaoxingzhai/core/interpretation/daily_hexagram_interpretation.dart';
import 'package:zhaoxingzhai/core/interpretation/meihua_interpretation.dart';
import 'package:zhaoxingzhai/core/models/meihua_consultation_context.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';
import 'package:zhaoxingzhai/core/interpretation/ssgw_interpretation.dart';
import 'package:zhaoxingzhai/core/interpretation/tarot_interpretation.dart';
import 'package:zhaoxingzhai/core/interpretation/xiaoliuren_interpretation.dart';
import 'package:zhaoxingzhai/core/engine/ssgw/ssgw_divination.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/shared/result.dart';
import 'package:zhaoxingzhai/core/sync/sync_version_conflict.dart';
import 'package:zhaoxingzhai/core/engine/tarot/tarot_divination.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/features/history/data/ai_interpretation_snapshot.dart';
import 'package:zhaoxingzhai/features/history/data/history_cloud_sync.dart';
import 'package:zhaoxingzhai/features/history/data/history_sync_state.dart';
import 'package:zhaoxingzhai/features/fortune/domain/today_fortune.dart';
import 'package:zhaoxingzhai/features/compatibility/domain/compatibility_result.dart';

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
    'ssgw' => '灵签',
    'daily-hexagram' => '每日一卦',
    'meihua' => '梅花易数',
    'today-fortune' => '今日运势',
    'compatibility' => '合盘',
    _ => type,
  };

  /// 算法身份，用于判断旧结果能否被当前实现 replay。
  String get algorithmLabel => '$algorithmId v$algorithmVersion';

  AiInterpretationSnapshot? get aiInterpretation =>
      AiInterpretationSnapshot.tryParse(payload['aiInterpretation']);

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
    final fallback = <String, dynamic>{...metaMap, ...algorithmMap, ...payload};

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
          json['algorithmId'] as String? ??
          fallback['algorithm'] as String? ??
          'unknown',
      algorithmVersion:
          (json['algorithmVersion'] as num?)?.toInt() ??
          (fallback['algorithmVersion'] as num?)?.toInt() ??
          0,
      schemaVersion:
          json['schemaVersion'] as String? ??
          fallback['schemaVersion'] as String? ??
          'unknown',
      caseSnapshot: snapshot,
    );
  }
}

class DivinationHistoryRepository extends ChangeNotifier {
  static const String storageKey = 'zhaoxingzhai.divination_history.v1';
  static const String syncStorageKey =
      'zhaoxingzhai.divination_history_sync.v1';
  static const _maxRecords = 100;

  final Future<SharedPreferences> Function() _preferencesFactory;
  final HistoryCloudSync? _cloudSync;
  final AppDatabase? database;
  final List<DivinationHistoryRecord> _records = [];
  final Map<String, HistorySyncState> _syncStates = {};
  Future<void>? _loadFuture;
  bool _isLoaded = false;
  bool _processingSync = false;
  bool _isDisposed = false;
  Timer? _retryTimer;
  String? _loadError;

  DivinationHistoryRepository({
    Future<SharedPreferences> Function()? preferencesFactory,
    HistoryCloudSync? cloudSync,
    this.database,
  }) : _preferencesFactory =
           preferencesFactory ?? SharedPreferences.getInstance,
       _cloudSync = _retainCloudSync(cloudSync);

  static HistoryCloudSync? _retainCloudSync(HistoryCloudSync? value) => value;

  List<DivinationHistoryRecord> get records => List.unmodifiable(_records);
  bool get isLoaded => _isLoaded;
  String? get loadError => _loadError;
  HistorySyncState syncStateFor(String recordId) =>
      _syncStates[recordId] ??
      HistorySyncState(
        recordId: recordId,
        status: _cloudSync == null
            ? HistorySyncStatus.localOnly
            : HistorySyncStatus.pending,
      );

  static String tarotRecordId(TarotDrawResult result) =>
      'tarot:${result.timestamp.microsecondsSinceEpoch}';
  static String xiaoliurenRecordId(XiaoliurenData result) =>
      result.meta.resultId;
  static String ssgwRecordId(SsgwResult result) =>
      'ssgw:${result.timestamp.microsecondsSinceEpoch}';
  static String dailyHexagramRecordId(DailyHexagramResult result) =>
      result.isManual
      ? 'daily-hexagram:manual:${result.generatedAt.microsecondsSinceEpoch}'
      : 'daily-hexagram:${result.dateKey}:${result.caseKey ?? 'general'}';
  static String meihuaRecordId(MeihuaResult result) =>
      'meihua:${result.generatedAt.microsecondsSinceEpoch}:${result.method.name}';
  static String todayFortuneRecordId(TodayFortune result) =>
      'today-fortune:${result.dateKey}:${result.caseId ?? 'general'}';

  Future<void> ensureLoaded() => _loadFuture ??= _load();

  Future<void> refreshFromCloud() async {
    final cloudSync = _cloudSync;
    if (cloudSync == null || _isDisposed) return;
    await ensureLoaded();
    try {
      final cloudRecords = await cloudSync.fetchRecords().timeout(
        const Duration(seconds: 15),
      );
      if (_mergeCloudRecords(cloudRecords)) {
        await _persist();
        if (!_isDisposed) notifyListeners();
      }
      await processPendingSync();
    } catch (_) {
      // 登录后的即时刷新失败时保留本地历史，后续同步队列仍可重试。
    }
  }

  Future<void> _load() async {
    try {
      final localDatabase = database;
      if (localDatabase != null) {
        await _loadFromDatabase(localDatabase);
        await _migrateLegacyDataIfNeeded(localDatabase);
      } else {
        final preferences = await _preferencesFactory();
        _restoreRecords(preferences.getString(storageKey));
        _restoreSyncStates(preferences.getString(syncStorageKey));
      }
      if (_cloudSync != null) {
        try {
          final cloudRecords = await _cloudSync.fetchRecords().timeout(
            const Duration(seconds: 15),
          );
          final changed = _mergeCloudRecords(cloudRecords);
          if (changed) {
            await _persist();
          }
        } catch (_) {
          // 云端暂时不可用时仍优先展示本地历史，后续由同步队列重试。
        }
        for (final record in _records) {
          _syncStates.putIfAbsent(
            record.id,
            () => HistorySyncState(
              recordId: record.id,
              status: HistorySyncStatus.pending,
            ),
          );
        }
        await _persistSyncStates();
      }
      _loadError = null;
    } catch (error) {
      _loadError = error.toString();
    } finally {
      _isLoaded = true;
      notifyListeners();
      if (_cloudSync != null) {
        unawaited(processPendingSync());
      }
    }
  }

  Future<void> _loadFromDatabase(AppDatabase database) async {
    _records.clear();
    _syncStates.clear();
    for (final row in await database.loadHistoryRecords()) {
      try {
        final decoded = jsonDecode(row.recordJson);
        if (decoded is Map) {
          _records.add(
            DivinationHistoryRecord.fromJson(
              Map<String, dynamic>.from(decoded),
            ),
          );
        }
      } catch (_) {
        // 单条本地数据损坏时保留其余可读记录。
      }
    }
    for (final row in await database.loadHistorySyncStates()) {
      final decoded = jsonDecode(row.stateJson);
      final state = HistorySyncState.tryParse(decoded);
      if (state != null) {
        _syncStates[state.recordId] = state.status == HistorySyncStatus.syncing
            ? state.copyWith(status: HistorySyncStatus.pending)
            : state;
      }
    }
    _records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _migrateLegacyDataIfNeeded(AppDatabase database) async {
    const migrationKey = 'migration.shared_preferences.history.v1';
    if (await database.metadataValue(migrationKey) == 'done') return;
    final preferences = await _preferencesFactory();
    if (_records.isEmpty) {
      _restoreRecords(preferences.getString(storageKey));
    }
    if (_syncStates.isEmpty) {
      _restoreSyncStates(preferences.getString(syncStorageKey));
    }
    await _persist();
    await _persistSyncStates();
    await database.setMetadataValue(migrationKey, 'done');
  }

  void _restoreRecords(String? raw) {
    if (raw == null || raw.isEmpty) return;
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

  void _restoreSyncStates(String? raw) {
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return;
    for (final item in decoded) {
      final state = HistorySyncState.tryParse(item);
      if (state != null) {
        _syncStates[state.recordId] = state.status == HistorySyncStatus.syncing
            ? state.copyWith(status: HistorySyncStatus.pending)
            : state;
      }
    }
  }

  bool _mergeCloudRecords(List<CloudHistoryRecord> cloudRecords) {
    var changed = false;
    final now = DateTime.now();
    for (final cloudRecord in cloudRecords) {
      final record = cloudRecord.record;
      final index = _records.indexWhere((item) => item.id == record.id);
      final state = _syncStates[record.id];
      if (index < 0) {
        _records.add(record);
        changed = true;
      } else if (state != null &&
          state.status == HistorySyncStatus.synced &&
          (state.serverVersion == null ||
              cloudRecord.version > state.serverVersion!)) {
        _records[index] = record;
        changed = true;
      }
      if (state == null) {
        _syncStates[record.id] = HistorySyncState(
          recordId: record.id,
          status: HistorySyncStatus.synced,
          serverRecordId: cloudRecord.serverId,
          serverVersion: cloudRecord.version,
          lastSyncedAt: now,
        );
      } else {
        _syncStates[record.id] = state.copyWith(
          serverRecordId: cloudRecord.serverId,
          serverVersion: cloudRecord.version,
          status: state.status == HistorySyncStatus.localOnly
              ? HistorySyncStatus.pending
              : state.status,
        );
      }
    }
    if (changed) {
      _records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (_records.length > _maxRecords) {
        _records.removeRange(_maxRecords, _records.length);
      }
    }
    return changed;
  }

  Future<void> addTarot(
    TarotDrawResult result, {
    CaseSnapshot? caseSnapshot,
    DivinationQuestion? question,
  }) async {
    final interpretation = TarotInterpretation.build(
      result,
      question: question,
    );
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
        id: tarotRecordId(result),
        type: 'tarot',
        title: result.spreadName,
        summary: summary,
        createdAt: result.timestamp,
        algorithmId: result.algorithm.id,
        algorithmVersion: result.algorithm.version,
        schemaVersion: zhaoxingzhaiSchemaVersion,
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
          if (question != null && question.rawText.isNotEmpty)
            'question': question.toJson(),
          if (result.randomTrace != null)
            'randomTrace': result.randomTrace!.toJson(),
          'interpretation': interpretation.toJson(),
        },
      ),
    );
  }

  Future<void> addXiaoliuren(
    XiaoliurenData result, {
    CaseSnapshot? caseSnapshot,
    DivinationQuestion? question,
  }) async {
    final interpretation = XiaoliurenInterpretation.build(
      result,
      question: question,
    );
    await add(
      DivinationHistoryRecord(
        id: xiaoliurenRecordId(result),
        type: 'xiaoliuren',
        title: '${result.primary.name} · ${result.ruleLabel}',
        summary:
            '${result.timestamp.year}-${result.timestamp.month.toString().padLeft(2, '0')}-'
            '${result.timestamp.day.toString().padLeft(2, '0')} ${result.hourLabel}；'
            '月宫 ${result.sequence['month']!.name}，'
            '日宫 ${result.sequence['day']!.name}，'
            '时宫 ${result.sequence['hour']!.name}',
        createdAt: result.meta.calculatedAt.toLocal(),
        payload: {
          ...result.toJson(),
          if (question != null && question.rawText.isNotEmpty)
            'question': question.toJson(),
          'interpretation': interpretation.toJson(),
        },
        algorithmId: result.meta.algorithm,
        algorithmVersion: result.meta.algorithmVersion,
        schemaVersion: result.meta.schemaVersion,
        caseSnapshot: caseSnapshot,
      ),
    );
  }

  Future<void> addSsgw(
    SsgwResult result, {
    CaseSnapshot? caseSnapshot,
    DivinationQuestion? question,
  }) async {
    final interpretation = SsgwInterpretation.build(result, question: question);
    await add(
      DivinationHistoryRecord(
        id: ssgwRecordId(result),
        type: 'ssgw',
        title: result.sign.title,
        summary:
            '第${result.sign.number}签 · ${result.sign.poem.replaceAll('\n', ' ')}',
        createdAt: result.timestamp,
        payload: {
          ...result.toJson(),
          if (question != null && question.rawText.isNotEmpty)
            'question': question.toJson(),
          'interpretation': interpretation.toJson(),
        },
        algorithmId: result.algorithm.id,
        algorithmVersion: result.algorithm.version,
        schemaVersion: zhaoxingzhaiSchemaVersion,
        caseSnapshot: caseSnapshot,
      ),
    );
  }

  Future<void> addDailyHexagram(
    DailyHexagramResult result, {
    CaseSnapshot? caseSnapshot,
    DivinationQuestion? question,
  }) async {
    final interpretation = DailyHexagramInterpretation.build(
      result,
      question: question,
    );
    await add(
      DivinationHistoryRecord(
        id: dailyHexagramRecordId(result),
        type: 'daily-hexagram',
        title: '${result.original.symbol} ${result.original.name}',
        summary:
            '${result.dateKey}；变${result.changed.name}；互${result.inter.name}；'
            '${result.movingLines.length}个动爻',
        createdAt: result.generatedAt,
        payload: {
          ...result.toJson(),
          if (question != null && question.rawText.isNotEmpty)
            'question': question.toJson(),
          'interpretation': interpretation.toJson(),
        },
        algorithmId: result.algorithm.id,
        algorithmVersion: result.algorithm.version,
        schemaVersion: zhaoxingzhaiSchemaVersion,
        caseSnapshot: caseSnapshot,
      ),
    );
  }

  Future<void> addMeihua(
    MeihuaResult result, {
    CaseSnapshot? caseSnapshot,
    MeihuaConsultationContext? consultationContext,
  }) async {
    final interpretation = MeihuaInterpretation.build(
      result,
      topic: consultationContext?.topic ?? 'general',
      question: DivinationQuestion.parse(
        consultationContext?.question ?? '',
        topic: consultationContext?.topic ?? 'general',
      ),
    );
    await add(
      DivinationHistoryRecord(
        id: meihuaRecordId(result),
        type: 'meihua',
        title:
            '${result.original.symbol} ${result.original.name} 之 ${result.changed.name}',
        summary:
            '${result.methodLabel}；互${result.inter.name}；${result.movingYaoName}；'
            '体${result.tiGua.name}用${result.yongGua.name}，${result.tiYongRelation}',
        createdAt: result.generatedAt,
        payload: {
          ...result.toJson(),
          if (consultationContext != null && !consultationContext.isEmpty)
            'consultationContext': consultationContext.toJson(),
          'interpretation': interpretation.toJson(),
        },
        algorithmId: result.algorithm.id,
        algorithmVersion: result.algorithm.version,
        schemaVersion: zhaoxingzhaiSchemaVersion,
        caseSnapshot: caseSnapshot,
      ),
    );
  }

  Future<void> addTodayFortune(
    TodayFortune result, {
    CaseSnapshot? caseSnapshot,
  }) async {
    await add(
      DivinationHistoryRecord(
        id: todayFortuneRecordId(result),
        type: 'today-fortune',
        title: result.headline,
        summary: '${result.dateKey} · ${result.lunarDate} · ${result.summary}',
        createdAt: result.date,
        payload: {
          'dateKey': result.dateKey,
          'lunarDate': result.lunarDate,
          'dayGanZhi': result.dayGanZhi,
          'zodiac': result.zodiac,
          'clashZodiac': result.clashZodiac,
          'isClashing': result.isClashing,
          'level': result.level.name,
          'overallScore': result.overallScore,
          'headline': result.headline,
          'summary': result.summary,
          'luckyColor': result.luckyColor,
          'luckyDirection': result.luckyDirection,
          'luckyNumber': result.luckyNumber,
          'yi': result.yi,
          'ji': result.ji,
          'dimensions': [
            for (final item in result.dimensions)
              {
                'id': item.id,
                'label': item.label,
                'score': item.score,
                'summary': item.summary,
              },
          ],
          'evidence': result.evidence.toJson(),
        },
        algorithmId: result.algorithmId,
        algorithmVersion: result.algorithmVersion,
        schemaVersion: zhaoxingzhaiSchemaVersion,
        caseSnapshot: caseSnapshot,
      ),
    );
  }

  Future<void> addCompatibility(CompatibilityResult result) async {
    await add(
      DivinationHistoryRecord(
        id: result.stableId,
        type: 'compatibility',
        title: result.headline,
        summary: '${result.relation.label} · ${result.overview}',
        createdAt: DateTime.now(),
        payload: {
          'relation': result.relation.name,
          'score': result.score,
          'level': result.level,
          'headline': result.headline,
          'overview': result.overview,
          'firstZodiac': result.firstZodiac,
          'secondZodiac': result.secondZodiac,
          'firstElement': result.firstElement,
          'secondElement': result.secondElement,
          'strengths': result.strengths,
          'frictions': result.frictions,
          'actions': result.actions,
          'evidence': result.evidence.toJson(),
          'firstCaseSnapshot': result.first.toJson(),
          'secondCaseSnapshot': result.second.toJson(),
        },
        algorithmId: compatibilityAlgorithmId,
        algorithmVersion: compatibilityAlgorithmVersion,
        schemaVersion: zhaoxingzhaiSchemaVersion,
        caseSnapshot: result.first,
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
    if (_cloudSync != null) {
      _syncStates[record.id] = HistorySyncState(
        recordId: record.id,
        status: HistorySyncStatus.pending,
        serverRecordId: _syncStates[record.id]?.serverRecordId,
        serverVersion: _syncStates[record.id]?.serverVersion,
      );
      await _persistSyncStates();
    }
    notifyListeners();
    if (_cloudSync != null) {
      unawaited(processPendingSync());
    }
  }

  /// Attaches the latest AI response to an existing result without creating
  /// a duplicate history entry. Safe for old records and missing IDs.
  Future<bool> updateAiInterpretation(
    String recordId,
    AiInterpretationResponse response, {
    String answerStyle = 'balanced',
  }) async {
    await ensureLoaded();
    final index = _records.indexWhere((record) => record.id == recordId);
    if (index < 0) {
      return false;
    }
    final record = _records[index];
    final payload = <String, dynamic>{
      ...record.payload,
      'aiInterpretation': AiInterpretationSnapshot.fromResponse(
        response,
        answerStyle: answerStyle,
      ).toJson(),
    };
    _records[index] = DivinationHistoryRecord(
      id: record.id,
      type: record.type,
      title: record.title,
      summary: record.summary,
      createdAt: record.createdAt,
      payload: payload,
      algorithmId: record.algorithmId,
      algorithmVersion: record.algorithmVersion,
      schemaVersion: record.schemaVersion,
      caseSnapshot: record.caseSnapshot,
    );
    await _persist();
    if (_cloudSync != null) {
      final previous = _syncStates[recordId];
      _syncStates[recordId] = HistorySyncState(
        recordId: recordId,
        status: HistorySyncStatus.pending,
        serverRecordId: previous?.serverRecordId,
        serverVersion: previous?.serverVersion,
      );
      await _persistSyncStates();
    }
    notifyListeners();
    if (_cloudSync != null) {
      unawaited(processPendingSync());
    }
    return true;
  }

  Future<void> delete(String id) async {
    await ensureLoaded();
    final state = _syncStates[id];
    _records.removeWhere((record) => record.id == id);
    await _persist();
    if (_cloudSync != null && state?.serverRecordId != null) {
      _syncStates[id] = state!.copyWith(
        status: HistorySyncStatus.pendingDelete,
        clearError: true,
        clearNextRetry: true,
      );
      await _persistSyncStates();
      unawaited(processPendingSync());
    } else {
      _syncStates.remove(id);
      await _persistSyncStates();
    }
    notifyListeners();
  }

  Future<void> clear() async {
    await ensureLoaded();
    _records.clear();
    for (final entry in _syncStates.entries.toList()) {
      if (entry.value.serverRecordId != null) {
        _syncStates[entry.key] = entry.value.copyWith(
          status: HistorySyncStatus.pendingDelete,
        );
      } else {
        _syncStates.remove(entry.key);
      }
    }
    await _persist();
    await _persistSyncStates();
    notifyListeners();
    if (_cloudSync != null) {
      unawaited(processPendingSync());
    }
  }

  Future<void> clearLocalData() async {
    await ensureLoaded();
    _retryTimer?.cancel();
    _records.clear();
    _syncStates.clear();
    final localDatabase = database;
    if (localDatabase != null) {
      await localDatabase.replaceHistoryRecords(const []);
      await localDatabase.replaceHistorySyncStates(const []);
    }
    final preferences = await _preferencesFactory();
    await preferences.remove(storageKey);
    await preferences.remove(syncStorageKey);
    notifyListeners();
  }

  Future<void> retrySync(String recordId) async {
    await ensureLoaded();
    final state = _syncStates[recordId];
    if (state == null || _cloudSync == null) {
      return;
    }
    _syncStates[recordId] = state.copyWith(
      status: state.status == HistorySyncStatus.pendingDelete
          ? HistorySyncStatus.pendingDelete
          : HistorySyncStatus.pending,
      retryCount: 0,
      clearNextRetry: true,
      clearError: true,
    );
    await _persistSyncStates();
    notifyListeners();
    unawaited(processPendingSync());
  }

  Future<void> processPendingSync() async {
    if (_cloudSync == null || _processingSync) {
      return;
    }
    _processingSync = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    try {
      final now = DateTime.now();
      final candidates = _syncStates.values.where((state) {
        final isPending =
            state.status == HistorySyncStatus.pending ||
            state.status == HistorySyncStatus.pendingDelete ||
            state.status == HistorySyncStatus.failed;
        return isPending &&
            (state.nextRetryAt == null || !state.nextRetryAt!.isAfter(now));
      }).toList();
      for (final state in candidates) {
        await _processSyncState(state);
      }
    } finally {
      _processingSync = false;
      _scheduleNextRetry();
    }
  }

  Future<void> _processSyncState(HistorySyncState initialState) async {
    var state = _syncStates[initialState.recordId];
    if (state == null) {
      return;
    }
    if (state.status == HistorySyncStatus.pendingDelete) {
      try {
        if (state.serverRecordId != null) {
          await _cloudSync!
              .deleteRecord(
                state.serverRecordId!,
                baseVersion: state.serverVersion,
              )
              .timeout(const Duration(seconds: 15));
        }
        _syncStates.remove(state.recordId);
        await _persistSyncStates();
        notifyListeners();
      } on SyncVersionConflict {
        try {
          await _acceptRemoteRecord(state.recordId);
        } catch (error) {
          await _markSyncFailure(state, error, deleting: true);
        }
      } catch (error) {
        await _markSyncFailure(state, error, deleting: true);
      }
      return;
    }

    final activeState = state;
    DivinationHistoryRecord? record;
    for (final candidate in _records) {
      if (candidate.id == activeState.recordId) {
        record = candidate;
        break;
      }
    }
    if (record == null) {
      _syncStates.remove(activeState.recordId);
      await _persistSyncStates();
      return;
    }
    _syncStates[activeState.recordId] = activeState.copyWith(
      status: HistorySyncStatus.syncing,
      clearError: true,
    );
    await _persistSyncStates();
    notifyListeners();
    try {
      final writeResult = await _cloudSync!
          .syncRecord(record, baseVersion: activeState.serverVersion)
          .timeout(const Duration(seconds: 15));
      final ai = record.aiInterpretation;
      if (ai != null) {
        await _cloudSync
            .syncAiInterpretation(
              record,
              AiInterpretationResponse(
                content: ai.content,
                source: ai.source,
                providerId: ai.providerId,
                modelId: ai.modelId,
                promptVersion: ai.promptVersion,
                generatedAt: ai.generatedAt,
                evidenceMethodId: ai.evidenceMethodId,
                fallbackReason: ai.fallbackReason,
                reading: ai.reading,
              ),
              answerStyle: ai.answerStyle,
              serverRecordId: writeResult.serverId,
            )
            .timeout(const Duration(seconds: 15));
      }
      state = _syncStates[activeState.recordId];
      if (state?.status == HistorySyncStatus.pendingDelete) {
        await _cloudSync
            .deleteRecord(
              writeResult.serverId,
              baseVersion: writeResult.version,
            )
            .timeout(const Duration(seconds: 15));
        _syncStates.remove(record.id);
      } else {
        _syncStates[record.id] = HistorySyncState(
          recordId: record.id,
          status: HistorySyncStatus.synced,
          serverRecordId: writeResult.serverId,
          serverVersion: writeResult.version,
          lastSyncedAt: DateTime.now(),
        );
      }
      await _persistSyncStates();
      notifyListeners();
    } on SyncVersionConflict {
      try {
        await _acceptRemoteRecord(record.id);
      } catch (error) {
        await _markSyncFailure(_syncStates[record.id] ?? initialState, error);
      }
    } catch (error) {
      await _markSyncFailure(_syncStates[record.id] ?? initialState, error);
    }
  }

  Future<void> _acceptRemoteRecord(String recordId) async {
    final cloudSync = _cloudSync;
    if (cloudSync == null) return;
    final remoteRecords = await cloudSync.fetchRecords();
    CloudHistoryRecord? match;
    for (final item in remoteRecords) {
      if (item.record.id == recordId) {
        match = item;
        break;
      }
    }
    if (match == null) {
      throw StateError('检测到历史版本冲突，但云端未返回对应记录');
    }
    final index = _records.indexWhere((item) => item.id == recordId);
    if (index < 0) {
      _records.add(match.record);
    } else {
      _records[index] = match.record;
    }
    _records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _syncStates[recordId] = HistorySyncState(
      recordId: recordId,
      status: HistorySyncStatus.synced,
      serverRecordId: match.serverId,
      serverVersion: match.version,
      lastSyncedAt: DateTime.now(),
      lastError: '该记录已在其他设备更新，已保留云端最新版本',
    );
    await _persist();
    await _persistSyncStates();
    notifyListeners();
  }

  Future<void> _markSyncFailure(
    HistorySyncState state,
    Object error, {
    bool deleting = false,
  }) async {
    final retryCount = state.retryCount + 1;
    final delay = _retryDelay(retryCount);
    _syncStates[state.recordId] = state.copyWith(
      status: deleting
          ? HistorySyncStatus.pendingDelete
          : HistorySyncStatus.failed,
      retryCount: retryCount,
      nextRetryAt: DateTime.now().add(delay),
      lastError: error.toString(),
    );
    await _persistSyncStates();
    notifyListeners();
  }

  static Duration _retryDelay(int retryCount) => switch (retryCount) {
    1 => const Duration(seconds: 10),
    2 => const Duration(seconds: 30),
    3 => const Duration(minutes: 2),
    4 => const Duration(minutes: 10),
    _ => const Duration(hours: 1),
  };

  void _scheduleNextRetry() {
    if (_isDisposed) {
      return;
    }
    final now = DateTime.now();
    final next = _syncStates.values
        .where(
          (state) =>
              (state.status == HistorySyncStatus.failed ||
                  state.status == HistorySyncStatus.pendingDelete) &&
              state.nextRetryAt != null,
        )
        .map((state) => state.nextRetryAt!)
        .fold<DateTime?>(
          null,
          (current, value) =>
              current == null || value.isBefore(current) ? value : current,
        );
    if (next == null) {
      return;
    }
    final delay = next.isAfter(now) ? next.difference(now) : Duration.zero;
    _retryTimer = Timer(delay, () => unawaited(processPendingSync()));
  }

  Future<void> _persist() async {
    final localDatabase = database;
    if (localDatabase != null) {
      await localDatabase.replaceHistoryRecords(
        _records.map(
          (record) => LocalHistoryRecordsCompanion.insert(
            id: record.id,
            recordJson: jsonEncode(record.toJson()),
            createdAt: record.createdAt,
          ),
        ),
      );
      return;
    }
    final preferences = await _preferencesFactory();
    final encoded = jsonEncode(
      _records.map((record) => record.toJson()).toList(),
    );
    final saved = await preferences.setString(storageKey, encoded);
    if (!saved) {
      throw StateError('本地历史记录写入失败');
    }
  }

  Future<void> _persistSyncStates() async {
    final localDatabase = database;
    if (localDatabase != null) {
      await localDatabase.replaceHistorySyncStates(
        _syncStates.values.map(
          (state) => LocalHistorySyncStatesCompanion.insert(
            recordId: state.recordId,
            stateJson: jsonEncode(state.toJson()),
          ),
        ),
      );
      return;
    }
    final preferences = await _preferencesFactory();
    await preferences.setString(
      syncStorageKey,
      jsonEncode(_syncStates.values.map((state) => state.toJson()).toList()),
    );
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _retryTimer?.cancel();
    super.dispose();
  }
}
