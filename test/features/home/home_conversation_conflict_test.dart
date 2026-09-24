import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/ai/ai_backend_config.dart';
import 'package:zhaoxingzhai/core/sync/sync_version_conflict.dart';
import 'package:zhaoxingzhai/features/home/data/home_conversation_cloud_sync.dart';
import 'package:zhaoxingzhai/features/home/data/home_conversation_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('会话云端 409 会解析为统一版本冲突', () async {
    SharedPreferences.setMockInitialValues({});
    final sync = HomeConversationCloudSync(
      client: MockClient(
        (_) async => mockResponse({
          'detail': {'resource': 'conversation', 'currentVersion': 4},
        }, 409),
      ),
      accessToken: () async => null,
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );
    final conversation = HomeConversation(
      id: 'home:conflict',
      messages: [
        HomeConversationMessage(
          text: '问题',
          createdAt: DateTime.utc(2026, 9, 24),
        ),
      ],
      updatedAt: DateTime.utc(2026, 9, 24),
    );

    await expectLater(
      sync.upsert(conversation, baseVersion: 3),
      throwsA(
        isA<SyncVersionConflict>()
            .having((error) => error.resource, 'resource', 'conversation')
            .having((error) => error.currentVersion, 'currentVersion', 4),
      ),
    );
  });

  test('会话冲突可以选择云端版本覆盖本地', () async {
    SharedPreferences.setMockInitialValues({});
    late String conversationId;
    final sync = HomeConversationCloudSync(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          return mockResponse({
            'detail': {'resource': 'conversation', 'currentVersion': 2},
          }, 409);
        }
        return mockResponse([
          {
            'id': 'server-id',
            'clientId': conversationId,
            'version': 2,
            'createdAt': '2026-09-24T00:00:00.000Z',
            'updatedAt': '2026-09-24T01:00:00.000Z',
            'messages': [
              {'text': '云端问题', 'createdAt': '2026-09-24T01:00:00.000Z'},
            ],
          },
        ], 200);
      }),
      accessToken: () async => null,
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );
    final repository = HomeConversationRepository(cloudSync: sync);

    final local = await repository.append(text: '本地问题');
    conversationId = local.id;
    expect(repository.conflicts, hasLength(1));

    await repository.resolveConflictUseCloud(conversationId);

    expect(repository.conflicts, isEmpty);
    expect(repository.conversations.single.messages.single.text, '云端问题');
  });

  test('保留本地时基于最新云端版本覆盖', () async {
    SharedPreferences.setMockInitialValues({});
    var postCalls = 0;
    String? conversationId;
    Object? resolvedBody;
    final sync = HomeConversationCloudSync(
      client: MockClient((request) async {
        if (request.method == 'GET') {
          return mockResponse([
            {
              'id': 'server-id',
              'clientId': conversationId,
              'version': 4,
              'createdAt': '2026-09-24T00:00:00.000Z',
              'updatedAt': '2026-09-24T01:00:00.000Z',
              'messages': [
                {'text': '云端内容', 'createdAt': '2026-09-24T01:00:00.000Z'},
              ],
            },
          ], 200);
        }
        postCalls++;
        if (postCalls == 1) {
          return mockResponse({
            'detail': {'resource': 'conversation', 'currentVersion': 4},
          }, 409);
        }
        resolvedBody = jsonDecode(request.body);
        return mockResponse({
          'id': 'server-id',
          'clientId': conversationId,
          'version': 5,
          'createdAt': '2026-09-24T00:00:00.000Z',
          'updatedAt': '2026-09-24T02:00:00.000Z',
          'messages': [
            {'text': '本地内容', 'createdAt': '2026-09-24T02:00:00.000Z'},
          ],
        }, 200);
      }),
      accessToken: () async => null,
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );
    final repository = HomeConversationRepository(cloudSync: sync);
    final local = await repository.append(text: '本地内容');
    conversationId = local.id;

    await repository.resolveConflictKeepLocal(local);

    expect((resolvedBody as Map<String, dynamic>)['baseVersion'], 4);
    expect(repository.conflicts, isEmpty);
    expect(repository.conversations.single.cloudVersion, 5);
  });

  test('修改已同步会话时携带已保存的云端版本', () async {
    SharedPreferences.setMockInitialValues({});
    Object? postedBody;
    final sync = HomeConversationCloudSync(
      client: MockClient((request) async {
        if (request.method == 'GET') {
          return mockResponse([
            {
              'id': 'server-id',
              'clientId': 'home:versioned',
              'version': 5,
              'createdAt': '2026-09-24T00:00:00.000Z',
              'updatedAt': '2026-09-24T00:00:00.000Z',
              'messages': [
                {'text': '旧问题', 'createdAt': '2026-09-24T00:00:00.000Z'},
              ],
            },
          ], 200);
        }
        postedBody = jsonDecode(request.body);
        return mockResponse({
          'id': 'server-id',
          'clientId': 'home:versioned',
          'version': 6,
          'createdAt': '2026-09-24T00:00:00.000Z',
          'updatedAt': '2026-09-24T02:00:00.000Z',
          'messages': [
            {'text': '旧问题', 'createdAt': '2026-09-24T00:00:00.000Z'},
            {'text': '新问题', 'createdAt': '2026-09-24T02:00:00.000Z'},
          ],
        }, 200);
      }),
      accessToken: () async => null,
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );
    final repository = HomeConversationRepository(cloudSync: sync);
    await repository.syncFromCloud();

    await repository.append(text: '新问题', conversationId: 'home:versioned');

    expect((postedBody as Map<String, dynamic>)['baseVersion'], 5);
    expect(repository.conversations.single.cloudVersion, 6);
  });

  test('删除发生版本冲突时恢复本地会话', () async {
    SharedPreferences.setMockInitialValues({});
    final sync = HomeConversationCloudSync(
      client: MockClient((request) async {
        if (request.method == 'GET') {
          return mockResponse([
            {
              'id': 'server-id',
              'clientId': 'home:delete-conflict',
              'version': 3,
              'createdAt': '2026-09-24T00:00:00.000Z',
              'updatedAt': '2026-09-24T00:00:00.000Z',
              'messages': [
                {'text': '待删除会话', 'createdAt': '2026-09-24T00:00:00.000Z'},
              ],
            },
          ], 200);
        }
        return mockResponse({
          'detail': {'resource': 'conversation', 'currentVersion': 4},
        }, 409);
      }),
      accessToken: () async => null,
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );
    final repository = HomeConversationRepository(cloudSync: sync);
    await repository.syncFromCloud();

    await repository.delete('home:delete-conflict');

    expect(repository.conversations, hasLength(1));
    expect(repository.conflicts, hasLength(1));
  });
}

http.Response mockResponse(Object? body, int statusCode) => http.Response(
  body is String ? body : jsonEncode(body),
  statusCode,
  headers: {'content-type': 'application/json'},
);
