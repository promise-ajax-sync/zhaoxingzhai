import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zhaoxingzhai/core/ai/ai_backend_config.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/ai/backend_ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/ai/local_ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/models/divination_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

void main() {
  const request = AiInterpretationRequest(
    question: DivinationQuestion(
      rawText: '今天工作上应该怎么做',
      topic: 'career',
      intent: DivinationQuestionIntent.action,
    ),
    evidence: DivinationEvidence(
      methodId: 'daily-hexagram',
      version: 1,
      calculationFacts: [],
      supportingEvidence: [],
      counterEvidence: [],
      limitations: [],
      summary: '以本卦和动爻为依据。',
    ),
    localAnswer: '先完成已有安排。',
    methodLabel: '每日一卦',
    answerStyle: 'chat',
  );

  test('后端地址规范化并生成解释接口地址', () {
    const config = AiBackendConfig(baseUrl: 'http://127.0.0.1:8000/');
    expect(
      config.interpretUri.toString(),
      'http://127.0.0.1:8000/api/v1/interpret',
    );
  });

  test('成功发送 Flutter 请求并解析后端响应', () async {
    final client = MockClient((http.Request actual) async {
      expect(actual.method, 'POST');
      expect(actual.url.path, '/api/v1/interpret');
      final body = jsonDecode(actual.body) as Map<String, dynamic>;
      expect(body['question']['rawText'], '今天工作上应该怎么做');
      expect(body['evidence']['methodId'], 'daily-hexagram');
      return http.Response(
        jsonEncode({
          'content': '今天先完成已有安排，再观察变化。',
          'source': 'remote',
          'providerId': 'openai-compatible',
          'modelId': 'test-model',
          'promptVersion': 2,
          'generatedAt': '2026-09-18T08:00:00Z',
          'evidenceMethodId': 'daily-hexagram',
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final service = BackendAiInterpretationService(
      client,
      const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );

    final response = await service.interpret(request);

    expect(response.source, AiAnswerSource.remote);
    expect(response.modelId, 'test-model');
    expect(response.content, contains('完成已有安排'));
  });

  test('后端不可用时通过弹性服务回落到本地回答', () async {
    final backend = BackendAiInterpretationService(
      MockClient((_) async => http.Response('service unavailable', 503)),
      const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );
    final service = ResilientAiInterpretationService(
      primary: backend,
      fallback: const LocalAiInterpretationService(),
    );

    final response = await service.interpret(request);

    expect(response.usedFallback, isTrue);
    expect(response.content, contains('先完成已有安排'));
    expect(response.fallbackReason, contains('503'));
  });

  test('成功状态但响应结构损坏时抛出格式错误', () async {
    final service = BackendAiInterpretationService(
      MockClient((_) async => http.Response('{}', 200)),
      const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );

    await expectLater(
      service.interpret(request),
      throwsA(isA<AiBackendException>()),
    );
  });

  test('422 响应会显示校验失败的字段路径', () async {
    final service = BackendAiInterpretationService(
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            'detail': [
              {
                'type': 'string_too_long',
                'loc': ['body', 'evidence', 'summary'],
                'msg': 'String should have at most 8000 characters',
              },
            ],
          }),
          422,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
      const AiBackendConfig(baseUrl: 'http://127.0.0.1:8000'),
    );

    await expectLater(
      service.interpret(request),
      throwsA(
        isA<AiBackendException>()
            .having((error) => error.statusCode, 'statusCode', 422)
            .having(
              (error) => error.message,
              'message',
              contains('evidence.summary'),
            ),
      ),
    );
  });

  test('空问题会转换为当前术式的通用解读任务', () {
    const emptyQuestionRequest = AiInterpretationRequest(
      question: DivinationQuestion(
        rawText: '',
        topic: 'general',
        intent: DivinationQuestionIntent.general,
      ),
      evidence: DivinationEvidence(
        methodId: 'tarot',
        version: 1,
        calculationFacts: [],
        supportingEvidence: [],
        counterEvidence: [],
        limitations: [],
        summary: '当前牌阵摘要',
      ),
      localAnswer: '当前本地解读',
      methodLabel: '塔罗',
    );

    final json = emptyQuestionRequest.toJson();
    final question = json['question'] as Map<String, dynamic>;

    expect(question['rawText'], contains('综合解读本次塔罗结果'));
    expect(question['intent'], 'general');
    expect(question['intentLabel'], '通用解读');
  });
}
