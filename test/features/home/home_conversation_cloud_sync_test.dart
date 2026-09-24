import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/ai/ai_backend_config.dart';
import 'package:zhaoxingzhai/features/home/data/home_conversation_cloud_sync.dart';
import 'package:zhaoxingzhai/features/home/data/home_conversation_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('会话同步上传携带客户端 ID、消息和访问令牌', () async {
    SharedPreferences.setMockInitialValues({});
    late dynamic captured;
    final sync = HomeConversationCloudSync(
      client: MockClient((request) async {
        captured = request;
        return mockResponse({
          'id': 'server-id',
          'clientId': 'home:1:0',
          'title': '问题',
          'messages': [
            {'text': '问题', 'createdAt': '2026-09-24T00:00:00Z'},
          ],
          'version': 2,
          'createdAt': '2026-09-24T00:00:00Z',
          'updatedAt': '2026-09-24T00:00:00Z',
        }, 200);
      }),
      accessToken: () async => 'token',
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );
    final conversation = HomeConversation(
      id: 'home:1:0',
      messages: [
        HomeConversationMessage(
          text: '问题',
          createdAt: DateTime.utc(2026, 9, 24),
        ),
      ],
      updatedAt: DateTime.utc(2026, 9, 24),
    );

    final result = await sync.upsert(conversation, baseVersion: 1);

    expect(captured.url.path, '/api/v1/conversations');
    expect(captured.headers['Authorization'], 'Bearer token');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['clientId'], 'home:1:0');
    expect(body['baseVersion'], 1);
    expect(result.version, 2);
    expect(result.conversation.cloudVersion, 2);
  });

  test('会话同步可以拉取并解析消息', () async {
    SharedPreferences.setMockInitialValues({});
    final sync = HomeConversationCloudSync(
      client: MockClient(
        (_) async => mockResponse([
          {
            'id': 'server-id',
            'clientId': 'home:1:0',
            'title': '问题',
            'messages': [
              {'text': '问题', 'createdAt': '2026-09-24T00:00:00Z'},
            ],
            'version': 1,
            'createdAt': '2026-09-24T00:00:00Z',
            'updatedAt': '2026-09-24T00:00:00Z',
          },
        ], 200),
      ),
      accessToken: () async => null,
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );

    final result = await sync.fetch();

    expect(result, hasLength(1));
    expect(result.single.conversation.messages.single.text, '问题');
    expect(result.single.version, 1);
  });

  test('会话删除接受 204 和 404', () async {
    SharedPreferences.setMockInitialValues({});
    var calls = 0;
    final sync = HomeConversationCloudSync(
      client: MockClient((_) async {
        calls++;
        return mockResponse(null, calls == 1 ? 204 : 404);
      }),
      accessToken: () async => null,
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );

    await sync.delete('home:1:0', baseVersion: 3);
    await sync.delete('home:1:0');
    expect(calls, 2);
  });

  test('会话删除携带云端版本', () async {
    SharedPreferences.setMockInitialValues({});
    late Uri capturedUri;
    final sync = HomeConversationCloudSync(
      client: MockClient((request) async {
        capturedUri = request.url;
        return mockResponse(null, 204);
      }),
      accessToken: () async => null,
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );

    await sync.delete('home:versioned', baseVersion: 7);

    expect(capturedUri.queryParameters['baseVersion'], '7');
  });
}

http.Response mockResponse(Object? body, int statusCode) => http.Response(
  body is String ? body : jsonEncode(body),
  statusCode,
  headers: {'content-type': 'application/json'},
);
