import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/ai/ai_backend_config.dart';
import 'package:zhaoxingzhai/core/auth/auth_session.dart';
import 'package:zhaoxingzhai/core/auth/session_token_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('登录会携带匿名设备并保存账号会话', () async {
    SharedPreferences.setMockInitialValues({});
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'accessToken': 'access-token',
            'refreshToken': 'refresh-token',
            'accessExpiresAt': '2099-09-19T08:00:00Z',
            'user': {
              'id': 'd10553ec-3434-48b5-bf7f-c5419a0b9540',
              'email': 'user@example.com',
              'displayName': '小明',
              'isAnonymous': false,
            },
          }),
        ),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final session = AuthSession(
      client: client,
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
      tokenStore: _MemoryTokenStore(),
    );

    await session.login(email: 'user@example.com', password: 'password123');

    expect(captured.url.path, '/api/v1/auth/login');
    expect(captured.headers['X-Device-ID']?.length, 64);
    expect(session.isSignedIn, isTrue);
    expect(session.user?.displayName, '小明');
    expect(await session.accessTokenForRequest(), 'access-token');
  });

  test('上传头像会发送授权 multipart 请求并更新本地用户', () async {
    SharedPreferences.setMockInitialValues({});
    http.Request? avatarRequest;
    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/auth/login') {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'accessToken': 'access-token',
              'refreshToken': 'refresh-token',
              'accessExpiresAt': '2099-09-19T08:00:00Z',
              'user': {
                'id': 'd10553ec-3434-48b5-bf7f-c5419a0b9540',
                'email': 'user@example.com',
                'displayName': '小明',
              },
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      avatarRequest = request;
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'id': 'd10553ec-3434-48b5-bf7f-c5419a0b9540',
            'email': 'user@example.com',
            'displayName': '小明',
            'avatarUrl': 'http://127.0.0.1:8000/media/avatars/user.jpg?v=1',
            'emailVerified': false,
          }),
        ),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final session = AuthSession(
      client: client,
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
      tokenStore: _MemoryTokenStore(),
    );
    await session.login(email: 'user@example.com', password: 'password123');

    await session.uploadAvatar(
      bytes: const [0xff, 0xd8, 0xff, 0x00],
      filename: '头像.jpg',
    );

    expect(avatarRequest?.url.path, '/api/v1/auth/avatar');
    expect(avatarRequest?.headers['authorization'], 'Bearer access-token');
    expect(
      avatarRequest?.headers['content-type'],
      startsWith('multipart/form-data; boundary='),
    );
    expect(avatarRequest?.bodyBytes, containsAllInOrder([0xff, 0xd8, 0xff]));
    expect(
      session.user?.avatarUrl,
      'http://127.0.0.1:8000/media/avatars/user.jpg?v=1',
    );
  });

  test('注销账号会复核密码并清除本地会话', () async {
    SharedPreferences.setMockInitialValues({});
    http.Request? deleteRequest;
    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/auth/login') {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'accessToken': 'access-token',
              'refreshToken': 'refresh-token',
              'accessExpiresAt': '2099-09-19T08:00:00Z',
              'user': {
                'id': 'd10553ec-3434-48b5-bf7f-c5419a0b9540',
                'email': 'user@example.com',
              },
            }),
          ),
          200,
        );
      }
      deleteRequest = request;
      return http.Response('', 204);
    });
    final session = AuthSession(
      client: client,
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
      tokenStore: _MemoryTokenStore(),
    );
    await session.login(email: 'user@example.com', password: 'password123');

    await session.deleteAccount(password: 'password123');

    expect(deleteRequest?.method, 'DELETE');
    expect(deleteRequest?.url.path, '/api/v1/auth/me');
    expect(deleteRequest?.headers['authorization'], 'Bearer access-token');
    expect(jsonDecode(deleteRequest!.body), {
      'password': 'password123',
      'confirmation': 'DELETE',
    });
    expect(session.isSignedIn, isFalse);
    expect(session.user, isNull);
  });

  test('个人数据导出会携带授权并返回格式化 JSON', () async {
    SharedPreferences.setMockInitialValues({});
    http.Request? exportRequest;
    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/auth/login') {
        return http.Response(
          jsonEncode({
            'accessToken': 'access-token',
            'refreshToken': 'refresh-token',
            'accessExpiresAt': '2099-09-19T08:00:00Z',
            'user': {
              'id': 'd10553ec-3434-48b5-bf7f-c5419a0b9540',
              'email': 'user@example.com',
            },
          }),
          200,
        );
      }
      exportRequest = request;
      return http.Response(
        jsonEncode({
          'schemaVersion': 'zhaoxingzhai-account-export-v1',
          'cases': [],
          'records': [],
        }),
        200,
      );
    });
    final session = AuthSession(
      client: client,
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
      tokenStore: _MemoryTokenStore(),
    );
    await session.login(email: 'user@example.com', password: 'password123');

    final exported = await session.exportAccountData();

    expect(exportRequest?.url.path, '/api/v1/auth/me/export');
    expect(exportRequest?.headers['authorization'], 'Bearer access-token');
    expect(exported, contains('zhaoxingzhai-account-export-v1'));
    expect(exported, contains('\n  "cases"'));
  });
}

class _MemoryTokenStore implements SessionTokenStore {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
