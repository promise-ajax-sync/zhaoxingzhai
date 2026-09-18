import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/ai/ai_prompt_builder.dart';
import 'package:zhaoxingzhai/core/ai/local_ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/models/divination_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

void main() {
  const question = DivinationQuestion(
    rawText: '这件事近期会不会成功',
    topic: 'career',
    intent: DivinationQuestionIntent.yesNo,
  );
  const evidence = DivinationEvidence(
    methodId: 'xiaoliuren',
    version: 1,
    calculationFacts: [
      DivinationEvidenceItem(
        id: 'primary',
        label: '主证',
        detail: '时宫大安',
      ),
    ],
    supportingEvidence: [],
    counterEvidence: [
      DivinationEvidenceItem(
        id: 'counter',
        label: '反向约束',
        detail: '吉宫不保证必然成功。',
      ),
    ],
    limitations: [
      DivinationEvidenceItem(
        id: 'limit',
        label: '能力边界',
        detail: '不能替代现实决策。',
      ),
    ],
    summary: '以时宫大安为主证。',
  );
  const request = AiInterpretationRequest(
    question: question,
    evidence: evidence,
    localAnswer: '当前偏向有条件地可行。',
    methodLabel: '小六壬',
  );

  test('提示词明确限制 AI 不得修改本地算法结果', () {
    final system = AiInterpretationPromptBuilder.systemPrompt(request);
    final user = AiInterpretationPromptBuilder.userPrompt(request);

    expect(system, contains('不得重新起卦'));
    expect(system, contains('不得编造细节'));
    expect(system, contains('最终时宫'));
    expect(system, isNot(contains('日常聊天风格')));
    expect(user, contains('这件事近期会不会成功'));
    expect(user, contains('xiaoliuren'));
    expect(user, contains('直接回应'));
  });

  test('回答风格与术式规则独立组合', () {
    const professionalRequest = AiInterpretationRequest(
      question: question,
      evidence: evidence,
      localAnswer: '当前偏向有条件地可行。',
      methodLabel: '小六壬',
      answerStyle: 'professional',
    );
    final system = AiInterpretationPromptBuilder.systemPrompt(
      professionalRequest,
    );

    expect(system, contains('专业分析风格'));
    expect(system, contains('月宫和日宫只保留为顺数计算轨迹'));
    expect(system, contains('不得解释成现实起因'));
  });

  test('五个现有术式都有独立提示词', () {
    expect(
      AiInterpretationPromptBuilder.methodInstruction('meihua', '梅花易数'),
      contains('体用关系'),
    );
    expect(
      AiInterpretationPromptBuilder.methodInstruction('tarot', '塔罗'),
      contains('牌阵位置'),
    );
    expect(
      AiInterpretationPromptBuilder.methodInstruction('xiaoliuren', '小六壬'),
      contains('最终时宫'),
    );
    expect(
      AiInterpretationPromptBuilder.methodInstruction('ssgw', '灵签'),
      contains('签题'),
    );
    expect(
      AiInterpretationPromptBuilder.methodInstruction(
        'daily-hexagram',
        '每日一卦',
      ),
      contains('当天'),
    );
  });

  test('本地服务使用直接回答、证据、反向信息和限制', () async {
    final response = await const LocalAiInterpretationService().interpret(
      request,
    );

    expect(response.usedFallback, isTrue);
    expect(response.providerId, 'local');
    expect(response.content, contains('有条件地可行'));
    expect(response.content, contains('吉宫不保证必然成功'));
    expect(response.content, contains('不能替代现实决策'));
    expect(response.evidenceMethodId, 'xiaoliuren');
  });

  test('远程服务失败时自动回落到本地解释并记录原因', () async {
    final service = ResilientAiInterpretationService(
      primary: _ThrowingService(),
      fallback: const LocalAiInterpretationService(),
    );

    final response = await service.interpret(request);

    expect(response.usedFallback, isTrue);
    expect(response.fallbackReason, contains('remote unavailable'));
    expect(response.content, contains('判断依据'));
  });

  test('远程服务超时时自动回落', () async {
    final service = ResilientAiInterpretationService(
      primary: _SlowService(),
      fallback: const LocalAiInterpretationService(),
      timeout: const Duration(milliseconds: 1),
    );

    final response = await service.interpret(request);

    expect(response.usedFallback, isTrue);
    expect(response.fallbackReason, contains('TimeoutException'));
  });
}

class _ThrowingService implements AiInterpretationService {
  @override
  Future<AiInterpretationResponse> interpret(
    AiInterpretationRequest request,
  ) => Future.error(StateError('remote unavailable'));
}

class _SlowService implements AiInterpretationService {
  @override
  Future<AiInterpretationResponse> interpret(
    AiInterpretationRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return AiInterpretationResponse(
      content: 'remote',
      source: AiAnswerSource.remote,
      providerId: 'test',
      modelId: 'test',
      promptVersion: 1,
      generatedAt: DateTime.now(),
      evidenceMethodId: request.evidence.methodId,
    );
  }
}
