import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/ai/ai_backend_config.dart';
import 'package:zhaoxingzhai/core/auth/auth_session.dart';
import 'package:zhaoxingzhai/core/sync/sync_version_conflict.dart';
import 'package:zhaoxingzhai/features/home/data/home_conversation_repository.dart';

class CloudConversation {
  const CloudConversation({required this.conversation, required this.version});

  final HomeConversation conversation;
  final int version;
}

class HomeConversationCloudSync {
  HomeConversationCloudSync({
    required this._client,
    required this._accessToken,
    AiBackendConfig? config,
    Future<SharedPreferences> Function()? preferencesFactory,
  }) : _config = config ?? AiBackendConfig.fromEnvironment(),
       _preferencesFactory =
           preferencesFactory ?? SharedPreferences.getInstance;

  final http.Client _client;
  final Future<String?> Function() _accessToken;
  final AiBackendConfig _config;
  final Future<SharedPreferences> Function() _preferencesFactory;

  Uri get _uri => _config.interpretUri.replace(path: '/api/v1/conversations');

  Future<List<CloudConversation>> fetch() async {
    final response = await _client.get(_uri, headers: await _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('会话同步下载失败：HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) throw const FormatException('会话同步响应格式无效');
    return decoded
        .map(_parse)
        .whereType<CloudConversation>()
        .toList(growable: false);
  }

  Future<CloudConversation> upsert(
    HomeConversation conversation, {
    int? baseVersion,
  }) async {
    final response = await _client.post(
      _uri,
      headers: await _headers(),
      body: jsonEncode({
        'clientId': conversation.id,
        'title': conversation.title,
        'messages': conversation.messages
            .map((message) => message.toJson())
            .toList(),
        'baseVersion': ?baseVersion,
      }),
    );
    if (response.statusCode == 409) throw _conflict(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('会话同步上传失败：HTTP ${response.statusCode}');
    }
    final parsed = _parse(jsonDecode(utf8.decode(response.bodyBytes)));
    if (parsed == null) throw const FormatException('会话同步响应格式无效');
    return parsed;
  }

  Future<void> delete(String clientId, {int? baseVersion}) async {
    final deleteUri = _uri.replace(
      path: '${_uri.path}/${Uri.encodeComponent(clientId)}',
      queryParameters: {'baseVersion': ?baseVersion?.toString()},
    );
    final response = await _client.delete(deleteUri, headers: await _headers());
    if (response.statusCode == 409) throw _conflict(response);
    if (response.statusCode != 204 && response.statusCode != 404) {
      throw StateError('会话删除同步失败：HTTP ${response.statusCode}');
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

  static CloudConversation? _parse(Object? raw) {
    if (raw is! Map || raw['id'] is! String || raw['version'] is! num) {
      return null;
    }
    final messages = raw['messages'] is List
        ? (raw['messages'] as List)
              .map(HomeConversationMessage.tryParse)
              .whereType<HomeConversationMessage>()
              .toList(growable: false)
        : const <HomeConversationMessage>[];
    final updatedAt = DateTime.tryParse(raw['updatedAt'] as String? ?? '');
    final createdAt =
        DateTime.tryParse(raw['createdAt'] as String? ?? '') ?? updatedAt;
    if (updatedAt == null || createdAt == null) return null;
    return CloudConversation(
      version: (raw['version'] as num).toInt(),
      conversation: HomeConversation(
        id: raw['clientId'] as String? ?? raw['id'] as String,
        messages: messages,
        updatedAt: updatedAt,
        cloudVersion: (raw['version'] as num).toInt(),
      ),
    );
  }

  static SyncVersionConflict _conflict(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final detail = decoded is Map ? decoded['detail'] : null;
      if (detail is Map) {
        return SyncVersionConflict(
          resource: detail['resource'] as String? ?? 'conversation',
          currentVersion: (detail['currentVersion'] as num?)?.toInt(),
        );
      }
    } catch (_) {}
    return const SyncVersionConflict(resource: 'conversation');
  }
}
