import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/ai/ai_backend_config.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/auth/auth_session.dart';
import 'package:zhaoxingzhai/core/sync/sync_version_conflict.dart';
import 'package:zhaoxingzhai/features/history/data/divination_history_repository.dart';

abstract interface class HistoryCloudSync {
  Future<List<CloudHistoryRecord>> fetchRecords();
  Future<CloudHistoryChangeBatch> fetchChanges(String? cursor);
  Future<CloudHistoryWriteResult> syncRecord(
    DivinationHistoryRecord record, {
    int? baseVersion,
  });
  Future<void> syncAiInterpretation(
    DivinationHistoryRecord record,
    AiInterpretationResponse response, {
    required String answerStyle,
    required String serverRecordId,
  });
  Future<void> deleteRecord(String serverRecordId, {int? baseVersion});
}

class CloudHistoryRecord {
  const CloudHistoryRecord({
    required this.serverId,
    required this.record,
    required this.version,
  });

  final String serverId;
  final DivinationHistoryRecord record;
  final int version;
}

class CloudHistoryWriteResult {
  const CloudHistoryWriteResult({
    required this.serverId,
    required this.version,
  });

  final String serverId;
  final int version;
}

class CloudHistoryChange {
  const CloudHistoryChange({
    required this.serverId,
    required this.clientRecordId,
    required this.version,
    required this.deleted,
    this.record,
  });

  final String serverId;
  final String clientRecordId;
  final int version;
  final bool deleted;
  final DivinationHistoryRecord? record;
}

class CloudHistoryChangeBatch {
  const CloudHistoryChangeBatch({required this.items, required this.cursor});

  final List<CloudHistoryChange> items;
  final String? cursor;
}

class BackendHistoryCloudSync implements HistoryCloudSync {
  BackendHistoryCloudSync({
    required http.Client client,
    AiBackendConfig? config,
    Future<SharedPreferences> Function()? preferencesFactory,
    Future<String?> Function()? accessToken,
  }) : _client = _retainClient(client),
       _config = config ?? AiBackendConfig.fromEnvironment(),
       _preferencesFactory =
           preferencesFactory ?? SharedPreferences.getInstance,
       _accessToken = accessToken ?? _noAccessToken;

  static http.Client _retainClient(http.Client value) => value;

  static Future<String?> _noAccessToken() async => null;

  final http.Client _client;
  final AiBackendConfig _config;
  final Future<SharedPreferences> Function() _preferencesFactory;
  final Future<String?> Function() _accessToken;

  Uri get _recordsUri => _config.interpretUri.replace(path: '/api/v1/records');
  Uri get _recordSyncUri =>
      _config.interpretUri.replace(path: '/api/v1/sync/records');

  @override
  Future<CloudHistoryChangeBatch> fetchChanges(String? cursor) async {
    final items = <CloudHistoryChange>[];
    var requestCursor = cursor;
    while (true) {
      final uri = _recordSyncUri.replace(
        queryParameters: {
          'cursor': ?requestCursor,
          'limit': '200',
        },
      );
      final response = await _client.get(uri, headers: await _headers());
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('历史增量同步失败：HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map || decoded['items'] is! List) {
        throw const FormatException('历史增量同步响应格式无效');
      }
      for (final raw in decoded['items'] as List) {
        final item = _parseChange(raw);
        if (item != null) items.add(item);
      }
      final next = decoded['nextCursor'];
      final hasMore = decoded['hasMore'] == true;
      if (next is String && next.isNotEmpty) requestCursor = next;
      if (!hasMore) {
        return CloudHistoryChangeBatch(items: items, cursor: requestCursor);
      }
      if (next is! String || next.isEmpty) {
        throw const FormatException('历史增量同步缺少下一页游标');
      }
    }
  }

  @override
  Future<List<CloudHistoryRecord>> fetchRecords() async {
    final response = await _client.get(_recordsUri, headers: await _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('云端历史下载失败：HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw const FormatException('云端历史响应格式无效');
    }
    return decoded
        .map(_parseCloudRecord)
        .whereType<CloudHistoryRecord>()
        .toList();
  }

  @override
  Future<CloudHistoryWriteResult> syncRecord(
    DivinationHistoryRecord record, {
    int? baseVersion,
  }) async {
    return _upsertRecord(record, baseVersion: baseVersion);
  }

  @override
  Future<void> deleteRecord(String serverRecordId, {int? baseVersion}) async {
    final uri = _recordsUri.replace(
      path: '${_recordsUri.path}/$serverRecordId',
      queryParameters: {if (baseVersion != null) 'baseVersion': '$baseVersion'},
    );
    final response = await _client.delete(uri, headers: await _headers());
    if (response.statusCode == 409) {
      throw _conflict(response, 'record');
    }
    if (response.statusCode != 204 && response.statusCode != 404) {
      throw StateError('历史删除同步失败：HTTP ${response.statusCode}');
    }
  }

  @override
  Future<void> syncAiInterpretation(
    DivinationHistoryRecord record,
    AiInterpretationResponse response, {
    required String answerStyle,
    required String serverRecordId,
  }) async {
    final aiUri = _recordsUri.replace(
      path: '${_recordsUri.path}/$serverRecordId/ai-interpretation',
    );
    final payload = <String, dynamic>{
      ...response.toJson(),
      'answerStyle': answerStyle,
      if (response.reading != null)
        'structuredReading': response.reading!.toJson(),
    }..remove('reading');
    final result = await _client.put(
      aiUri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    if (result.statusCode < 200 || result.statusCode >= 300) {
      throw StateError('AI 历史同步失败：HTTP ${result.statusCode}');
    }
  }

  Future<CloudHistoryWriteResult> _upsertRecord(
    DivinationHistoryRecord record, {
    int? baseVersion,
  }) async {
    final response = await _client.post(
      _recordsUri,
      headers: await _headers(),
      body: jsonEncode({
        'clientRecordId': record.id,
        'methodType': record.type,
        'title': record.title,
        'summary': record.summary,
        if (record.payload['question'] != null)
          'question': record.payload['question'],
        'resultPayload': record.payload,
        if (record.caseSnapshot != null)
          'caseSnapshot': record.caseSnapshot!.toJson(),
        'algorithmId': record.algorithmId,
        'algorithmVersion': record.algorithmVersion,
        'schemaVersion': record.schemaVersion,
        'occurredAt': record.createdAt.toUtc().toIso8601String(),
        'baseVersion': ?baseVersion,
      }),
    );
    if (response.statusCode == 409) {
      throw _conflict(response, 'record');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('历史同步失败：HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['id'] is! String) {
      throw const FormatException('历史同步响应缺少记录 ID');
    }
    return CloudHistoryWriteResult(
      serverId: decoded['id'] as String,
      version: (decoded['version'] as num?)?.toInt() ?? (baseVersion ?? 0) + 1,
    );
  }

  Future<Map<String, String>> _headers() async {
    final token = await _accessToken();
    return {
      'Content-Type': 'application/json',
      'X-Device-ID': await AuthSession.deviceId(_preferencesFactory),
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static CloudHistoryRecord? _parseCloudRecord(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final serverId = map['id'];
    final clientRecordId = map['clientRecordId'];
    final resultPayload = map['resultPayload'];
    final version = (map['version'] as num?)?.toInt() ?? 1;
    if (serverId is! String ||
        clientRecordId is! String ||
        resultPayload is! Map) {
      return null;
    }
    final payload = Map<String, dynamic>.from(resultPayload);
    final aiRaw = map['aiInterpretation'];
    if (aiRaw is Map) {
      final ai = Map<String, dynamic>.from(aiRaw);
      final structured = ai.remove('structuredReading');
      if (structured != null) ai['reading'] = structured;
      payload['aiInterpretation'] = ai;
    }
    try {
      return CloudHistoryRecord(
        serverId: serverId,
        version: version,
        record: DivinationHistoryRecord.fromJson({
          'id': clientRecordId,
          'type': map['methodType'],
          'title': map['title'],
          'summary': map['summary'],
          'createdAt': map['occurredAt'],
          'payload': payload,
          'algorithmId': map['algorithmId'],
          'algorithmVersion': map['algorithmVersion'],
          'schemaVersion': map['schemaVersion'],
          if (map['caseSnapshot'] != null) 'caseSnapshot': map['caseSnapshot'],
        }),
      );
    } catch (_) {
      return null;
    }
  }

  static CloudHistoryChange? _parseChange(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final serverId = map['id'];
    final clientRecordId = map['clientRecordId'];
    final version = map['version'];
    final deleted = map['deleted'];
    if (serverId is! String ||
        clientRecordId is! String ||
        version is! num ||
        deleted is! bool) {
      return null;
    }
    DivinationHistoryRecord? record;
    if (!deleted) {
      final recordRaw = map['record'];
      final parsed = _parseCloudRecord(recordRaw);
      if (parsed == null) return null;
      record = parsed.record;
    }
    return CloudHistoryChange(
      serverId: serverId,
      clientRecordId: clientRecordId,
      version: version.toInt(),
      deleted: deleted,
      record: record,
    );
  }

  static SyncVersionConflict _conflict(
    http.Response response,
    String fallbackResource,
  ) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final detail = decoded is Map ? decoded['detail'] : null;
      if (detail is Map) {
        return SyncVersionConflict(
          resource: detail['resource'] as String? ?? fallbackResource,
          currentVersion: (detail['currentVersion'] as num?)?.toInt(),
        );
      }
    } catch (_) {}
    return SyncVersionConflict(resource: fallbackResource);
  }
}
