import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/ai/ai_backend_config.dart';
import 'package:zhaoxingzhai/core/sync/sync_version_conflict.dart';
import 'package:zhaoxingzhai/features/history/data/divination_history_repository.dart';
import 'package:zhaoxingzhai/features/history/data/history_cloud_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('云同步发送匿名设备标识和完整历史载荷', () async {
    SharedPreferences.setMockInitialValues({});
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'id': '8a4eb90d-9dc7-4bd4-a395-b542c188ef61',
          'version': 2,
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final sync = BackendHistoryCloudSync(
      client: client,
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );
    final record = DivinationHistoryRecord(
      id: 'tarot:test-record',
      type: 'tarot',
      title: '单牌指引',
      summary: '测试摘要',
      createdAt: DateTime.utc(2026, 9, 19),
      payload: const {'spreadType': 'single'},
      algorithmId: 'tarot',
      algorithmVersion: 1,
      schemaVersion: '1.0.0',
    );

    final result = await sync.syncRecord(record, baseVersion: 1);

    expect(captured.url.path, '/api/v1/records');
    expect(captured.headers['X-Device-ID']?.length, 64);
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['clientRecordId'], record.id);
    expect(body['resultPayload'], record.payload);
    expect(body['algorithmId'], 'tarot');
    expect(body['baseVersion'], 1);
    expect(result.version, 2);
  });

  test('登录后云同步优先携带访问令牌', () async {
    SharedPreferences.setMockInitialValues({});
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(jsonEncode([]), 200);
    });
    final sync = BackendHistoryCloudSync(
      client: client,
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
      accessToken: () async => 'account-access-token',
    );

    await sync.fetchRecords();

    expect(captured.headers['Authorization'], 'Bearer account-access-token');
    expect(captured.headers['X-Device-ID'], isNotEmpty);
  });

  test('历史同步遇到 409 会返回可识别的版本冲突', () async {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'detail': {
            'code': 'sync_version_conflict',
            'resource': 'record',
            'currentVersion': 5,
          },
        }),
        409,
      ),
    );
    final sync = BackendHistoryCloudSync(
      client: client,
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );

    await expectLater(
      sync.syncRecord(_testRecord(), baseVersion: 4),
      throwsA(
        isA<SyncVersionConflict>()
            .having((error) => error.resource, 'resource', 'record')
            .having((error) => error.currentVersion, 'currentVersion', 5),
      ),
    );
  });

  test('云端历史会还原本地记录和结构化 AI 解读', () async {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode([
          {
            'id': '8a4eb90d-9dc7-4bd4-a395-b542c188ef61',
            'version': 3,
            'clientRecordId': 'tarot:cloud-record',
            'methodType': 'tarot',
            'title': '单牌指引',
            'summary': '云端摘要',
            'resultPayload': {'spreadType': 'single'},
            'algorithmId': 'tarot',
            'algorithmVersion': 1,
            'schemaVersion': '1.0.0',
            'occurredAt': '2026-09-19T08:00:00Z',
            'createdAt': '2026-09-19T08:00:00Z',
            'updatedAt': '2026-09-19T08:00:00Z',
            'aiInterpretation': {
              'id': 'ai-id',
              'recordId': '8a4eb90d-9dc7-4bd4-a395-b542c188ef61',
              'content': '云端 AI 解读',
              'source': 'remote',
              'providerId': 'openai-compatible',
              'modelId': 'test-model',
              'promptVersion': 4,
              'evidenceMethodId': 'tarot',
              'answerStyle': 'chat',
              'generatedAt': '2026-09-19T08:00:00Z',
              'createdAt': '2026-09-19T08:00:00Z',
              'structuredReading': {
                'headline': '云端结论',
                'plainLanguage': '通俗解释',
                'evidence': [],
                'risks': [],
                'actions': [],
                'boundary': '仅供参考',
                'closing': '慢慢看就好啦 ( ˘͈ ᵕ ˘͈ )',
              },
            },
          },
        ]),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    final sync = BackendHistoryCloudSync(
      client: client,
      config: const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );

    final records = await sync.fetchRecords();

    expect(records.single.record.id, 'tarot:cloud-record');
    expect(records.single.record.aiInterpretation?.reading?.headline, '云端结论');
  });
}

DivinationHistoryRecord _testRecord() => DivinationHistoryRecord(
  id: 'tarot:conflict-record',
  type: 'tarot',
  title: '冲突测试',
  summary: '测试摘要',
  createdAt: DateTime.utc(2026, 9, 21),
  payload: const {'spreadType': 'single'},
  algorithmId: 'tarot',
  algorithmVersion: 1,
  schemaVersion: '1.0.0',
);
