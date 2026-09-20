import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/ai/ai_backend_config.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/auth/auth_session.dart';
import 'package:zhaoxingzhai/features/history/data/divination_history_repository.dart';

abstract interface class HistoryCloudSync {
  Future<List<CloudHistoryRecord>> fetchRecords();
  Future<String> syncRecord(DivinationHistoryRecord record);
  Future<void> syncAiInterpretation(
    DivinationHistoryRecord record,
    AiInterpretationResponse response, {
    required String answerStyle,
  });
  Future<void> deleteRecord(String serverRecordId);
}

class CloudHistoryRecord {
  const CloudHistoryRecord({required this.serverId, required this.record});

  final String serverId;
  final DivinationHistoryRecord record;
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
  Future<String> syncRecord(DivinationHistoryRecord record) async {
    return _upsertRecord(record);
  }

  @override
  Future<void> deleteRecord(String serverRecordId) async {
    final uri = _recordsUri.replace(
      path: '${_recordsUri.path}/$serverRecordId',
    );
    final response = await _client.delete(uri, headers: await _headers());
    if (response.statusCode != 204 && response.statusCode != 404) {
      throw StateError('历史删除同步失败：HTTP ${response.statusCode}');
    }
  }

  @override
  Future<void> syncAiInterpretation(
    DivinationHistoryRecord record,
    AiInterpretationResponse response, {
    required String answerStyle,
  }) async {
    final serverId = await _upsertRecord(record);
    final aiUri = _recordsUri.replace(
      path: '${_recordsUri.path}/$serverId/ai-interpretation',
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

  Future<String> _upsertRecord(DivinationHistoryRecord record) async {
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
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('历史同步失败：HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['id'] is! String) {
      throw const FormatException('历史同步响应缺少记录 ID');
    }
    return decoded['id'] as String;
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
}
