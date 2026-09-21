import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/ai/ai_backend_config.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/sync/sync_version_conflict.dart';
import 'package:zhaoxingzhai/features/cases/data/case_cloud_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('角色更新会携带基础版本并保存服务端新版本', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({'id': 'server-case-1', 'version': 4}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final sync = CaseCloudSync(
      client: client,
      accessToken: () async => 'token',
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );
    final profile = CaseProfile.create(
      name: '测试角色',
      birthDateTime: DateTime(1990, 1, 1),
      now: DateTime(2026, 9, 21),
    );

    final result = await sync.upsert(profile, baseVersion: 3);

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['baseVersion'], 3);
    expect(result.serverId, 'server-case-1');
    expect(result.version, 4);
  });

  test('角色删除会把基础版本放入查询参数', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response('', 204);
    });
    final sync = CaseCloudSync(
      client: client,
      accessToken: () async => 'token',
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );

    await sync.delete('server-case-1', baseVersion: 7);

    expect(captured.url.queryParameters['baseVersion'], '7');
  });

  test('409 响应会解析为版本冲突而不是普通网络错误', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'detail': {
            'code': 'sync_version_conflict',
            'resource': 'case',
            'currentVersion': 6,
          },
        }),
        409,
        headers: {'content-type': 'application/json'},
      ),
    );
    final sync = CaseCloudSync(
      client: client,
      accessToken: () async => 'token',
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );
    final profile = CaseProfile.create(
      name: '冲突角色',
      birthDateTime: DateTime(1990, 1, 1),
      now: DateTime(2026, 9, 21),
    );

    await expectLater(
      sync.upsert(profile, baseVersion: 5),
      throwsA(
        isA<SyncVersionConflict>()
            .having((error) => error.resource, 'resource', 'case')
            .having((error) => error.currentVersion, 'currentVersion', 6),
      ),
    );
  });
}
