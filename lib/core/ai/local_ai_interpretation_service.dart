import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/ai/ai_prompt_builder.dart';

class LocalAiInterpretationService implements AiInterpretationService {
  const LocalAiInterpretationService();

  @override
  Future<AiInterpretationResponse> interpret(
    AiInterpretationRequest request,
  ) async {
    final limitations = request.evidence.limitations
        .map((item) => item.detail)
        .where((text) => text.trim().isNotEmpty)
        .join('；');
    final counter = request.evidence.counterEvidence
        .map((item) => item.detail)
        .where((text) => text.trim().isNotEmpty)
        .join('；');
    final content = [
      request.localAnswer.trim(),
      '判断依据：${request.evidence.summary}',
      if (counter.isNotEmpty) '反向信息：$counter',
      if (limitations.isNotEmpty) '能力边界：$limitations',
    ].join('\n\n');

    return AiInterpretationResponse(
      content: content,
      source: AiAnswerSource.localFallback,
      providerId: 'local',
      modelId: 'structured-reading',
      promptVersion: AiInterpretationPromptBuilder.promptVersion,
      generatedAt: DateTime.now(),
      evidenceMethodId: request.evidence.methodId,
    );
  }
}
