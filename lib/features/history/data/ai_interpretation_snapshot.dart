import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';

/// Persisted metadata and content for an AI interpretation attached to a
/// divination record. Older records simply omit this snapshot.
class AiInterpretationSnapshot {
  const AiInterpretationSnapshot({
    required this.content,
    required this.source,
    required this.providerId,
    required this.modelId,
    required this.promptVersion,
    required this.generatedAt,
    required this.evidenceMethodId,
    required this.answerStyle,
    this.fallbackReason,
    this.reading,
  });

  factory AiInterpretationSnapshot.fromResponse(
    AiInterpretationResponse response, {
    String answerStyle = 'balanced',
  }) => AiInterpretationSnapshot(
    content: response.content,
    source: response.source,
    providerId: response.providerId,
    modelId: response.modelId,
    promptVersion: response.promptVersion,
    generatedAt: response.generatedAt,
    evidenceMethodId: response.evidenceMethodId,
    answerStyle: answerStyle,
    fallbackReason: response.fallbackReason,
    reading: response.reading,
  );

  final String content;
  final AiAnswerSource source;
  final String providerId;
  final String modelId;
  final int promptVersion;
  final DateTime generatedAt;
  final String evidenceMethodId;
  final String answerStyle;
  final String? fallbackReason;
  final AiStructuredReading? reading;

  bool get usedFallback => source == AiAnswerSource.localFallback;

  Map<String, dynamic> toJson() => {
    'content': content,
    'source': source.id,
    'providerId': providerId,
    'modelId': modelId,
    'promptVersion': promptVersion,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'evidenceMethodId': evidenceMethodId,
    'answerStyle': answerStyle,
    if (fallbackReason != null) 'fallbackReason': fallbackReason,
    if (reading != null) 'reading': reading!.toJson(),
  };

  static AiInterpretationSnapshot? tryParse(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final response = AiInterpretationResponse.tryParse(raw);
    return response == null
        ? null
        : AiInterpretationSnapshot.fromResponse(
            response,
            answerStyle: raw['answerStyle'] as String? ?? 'balanced',
          );
  }
}
