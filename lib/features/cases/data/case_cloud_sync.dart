import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/ai/ai_backend_config.dart';
import 'package:zhaoxingzhai/core/auth/auth_session.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/sync/sync_version_conflict.dart';

class CloudCase {
  const CloudCase({
    required this.serverId,
    required this.profile,
    required this.version,
  });
  final String serverId;
  final CaseProfile profile;
  final int version;
}

class CloudCaseWriteResult {
  const CloudCaseWriteResult({required this.serverId, required this.version});

  final String serverId;
  final int version;
}

class CloudCaseChange {
  const CloudCaseChange({
    required this.serverId,
    required this.clientId,
    required this.version,
    required this.deleted,
    this.profile,
  });

  final String serverId;
  final String clientId;
  final int version;
  final bool deleted;
  final CaseProfile? profile;
}

class CloudCaseChangeBatch {
  const CloudCaseChangeBatch({required this.items, required this.cursor});

  final List<CloudCaseChange> items;
  final String? cursor;
}

class CaseCloudSync {
  CaseCloudSync({
    required http.Client client,
    required Future<String?> Function() accessToken,
    AiBackendConfig? config,
    Future<SharedPreferences> Function()? preferencesFactory,
  }) : _client = _retainClient(client),
       _accessToken = _retainAccessToken(accessToken),
       _config = config ?? AiBackendConfig.fromEnvironment(),
       _preferencesFactory =
           preferencesFactory ?? SharedPreferences.getInstance;

  static http.Client _retainClient(http.Client value) => value;
  static Future<String?> Function() _retainAccessToken(
    Future<String?> Function() value,
  ) => value;

  final http.Client _client;
  final Future<String?> Function() _accessToken;
  final AiBackendConfig _config;
  final Future<SharedPreferences> Function() _preferencesFactory;

  Uri get _casesUri => _config.interpretUri.replace(path: '/api/v1/cases');
  Uri get _caseSyncUri =>
      _config.interpretUri.replace(path: '/api/v1/sync/cases');

  Future<CloudCaseChangeBatch> fetchChanges(String? cursor) async {
    final items = <CloudCaseChange>[];
    var requestCursor = cursor;
    while (true) {
      final uri = _caseSyncUri.replace(
        queryParameters: {
          'cursor': ?requestCursor,
          'limit': '200',
        },
      );
      final response = await _client.get(uri, headers: await _headers());
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('角色增量同步失败：HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map || decoded['items'] is! List) {
        throw const FormatException('角色增量同步响应格式无效');
      }
      for (final raw in decoded['items'] as List) {
        final item = _parseChange(raw);
        if (item != null) items.add(item);
      }
      final next = decoded['nextCursor'];
      final hasMore = decoded['hasMore'] == true;
      if (next is String && next.isNotEmpty) {
        requestCursor = next;
      }
      if (!hasMore) {
        return CloudCaseChangeBatch(items: items, cursor: requestCursor);
      }
      if (next is! String || next.isEmpty) {
        throw const FormatException('角色增量同步缺少下一页游标');
      }
    }
  }

  Future<List<CloudCase>> fetchCases() async {
    final response = await _client.get(_casesUri, headers: await _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('角色下载失败：HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) throw const FormatException('角色响应格式无效');
    return decoded.map(_parse).whereType<CloudCase>().toList();
  }

  Future<CloudCaseWriteResult> upsert(
    CaseProfile profile, {
    int? baseVersion,
  }) async {
    final response = await _client.post(
      _casesUri,
      headers: await _headers(),
      body: jsonEncode({
        'clientId': profile.id,
        'name': profile.name,
        'profile': profile.toJson(),
        'baseVersion': ?baseVersion,
      }),
    );
    if (response.statusCode == 409) {
      throw _conflict(response, 'case');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('角色同步失败：HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['id'] is! String) {
      throw const FormatException('角色同步响应缺少 ID');
    }
    return CloudCaseWriteResult(
      serverId: decoded['id'] as String,
      version: (decoded['version'] as num?)?.toInt() ?? (baseVersion ?? 0) + 1,
    );
  }

  Future<void> delete(String serverId, {int? baseVersion}) async {
    final response = await _client.delete(
      _casesUri.replace(
        path: '${_casesUri.path}/$serverId',
        queryParameters: {
          if (baseVersion != null) 'baseVersion': '$baseVersion',
        },
      ),
      headers: await _headers(),
    );
    if (response.statusCode == 409) {
      throw _conflict(response, 'case');
    }
    if (response.statusCode != 204 && response.statusCode != 404) {
      throw StateError('角色删除同步失败：HTTP ${response.statusCode}');
    }
  }

  Future<Map<String, String>> _headers() async {
    final token = await _accessToken();
    return {
      'Content-Type': 'application/json',
      'X-Device-ID': await AuthSession.deviceId(_preferencesFactory),
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static CloudCase? _parse(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final id = json['id'];
    final profileJson = json['profile'];
    final version = (json['version'] as num?)?.toInt() ?? 1;
    if (id is! String || profileJson is! Map) return null;
    final profile = CaseProfile.tryFromJson(
      Map<String, dynamic>.from(profileJson),
    );
    if (profile == null) return null;
    return CloudCase(serverId: id, profile: profile, version: version);
  }

  static CloudCaseChange? _parseChange(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final serverId = json['id'];
    final clientId = json['clientId'];
    final version = json['version'];
    final deleted = json['deleted'];
    if (serverId is! String ||
        clientId is! String ||
        version is! num ||
        deleted is! bool) {
      return null;
    }
    CaseProfile? profile;
    if (!deleted && json['profile'] is Map) {
      profile = CaseProfile.tryFromJson(
        Map<String, dynamic>.from(json['profile'] as Map),
      );
      if (profile == null) return null;
    }
    return CloudCaseChange(
      serverId: serverId,
      clientId: clientId,
      version: version.toInt(),
      deleted: deleted,
      profile: profile,
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
