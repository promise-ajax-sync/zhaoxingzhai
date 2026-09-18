import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';

abstract interface class AiInterpretationService {
  Future<AiInterpretationResponse> interpret(
    AiInterpretationRequest request,
  );
}

class ResilientAiInterpretationService implements AiInterpretationService {
  const ResilientAiInterpretationService({
    required this.primary,
    required this.fallback,
    this.timeout = const Duration(seconds: 20),
  });

  final AiInterpretationService primary;
  final AiInterpretationService fallback;
  final Duration timeout;

  @override
  Future<AiInterpretationResponse> interpret(
    AiInterpretationRequest request,
  ) async {
    try {
      final response = await primary.interpret(request).timeout(timeout);
      if (response.content.trim().isEmpty) {
        throw const FormatException('AI 返回了空回答');
      }
      return response;
    } catch (error) {
      final response = await fallback.interpret(request);
      return AiInterpretationResponse(
        content: response.content,
        source: AiAnswerSource.localFallback,
        providerId: response.providerId,
        modelId: response.modelId,
        promptVersion: response.promptVersion,
        generatedAt: response.generatedAt,
        evidenceMethodId: response.evidenceMethodId,
        fallbackReason: error.toString(),
      );
    }
  }
}
