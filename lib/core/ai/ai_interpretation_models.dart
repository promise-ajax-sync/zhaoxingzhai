import 'package:zhaoxingzhai/core/models/divination_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

enum AiAnswerSource {
  remote('remote'),
  localFallback('local_fallback');

  const AiAnswerSource(this.id);
  final String id;

  static AiAnswerSource? tryParse(Object? raw) => switch (raw) {
    'remote' => AiAnswerSource.remote,
    'local_fallback' => AiAnswerSource.localFallback,
    _ => null,
  };
}

class AiInterpretationRequest {
  const AiInterpretationRequest({
    required this.question,
    required this.evidence,
    required this.localAnswer,
    required this.methodLabel,
    this.answerStyle = 'balanced',
    this.locale = 'zh-CN',
  });

  final DivinationQuestion question;
  final DivinationEvidence evidence;
  final String localAnswer;
  final String methodLabel;
  final String answerStyle;
  final String locale;

  Map<String, dynamic> toJson() => {
    'question': question.toJson(),
    'evidence': evidence.toJson(),
    'localAnswer': localAnswer,
    'methodLabel': methodLabel,
    'answerStyle': answerStyle,
    'locale': locale,
  };
}

class AiInterpretationResponse {
  const AiInterpretationResponse({
    required this.content,
    required this.source,
    required this.providerId,
    required this.modelId,
    required this.promptVersion,
    required this.generatedAt,
    required this.evidenceMethodId,
    this.fallbackReason,
  });

  final String content;
  final AiAnswerSource source;
  final String providerId;
  final String modelId;
  final int promptVersion;
  final DateTime generatedAt;
  final String evidenceMethodId;
  final String? fallbackReason;

  bool get usedFallback => source == AiAnswerSource.localFallback;

  static AiInterpretationResponse? tryParse(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(raw);
    final content = map['content'];
    final source = AiAnswerSource.tryParse(map['source']);
    final providerId = map['providerId'];
    final modelId = map['modelId'];
    final promptVersion = (map['promptVersion'] as num?)?.toInt();
    final generatedAtRaw = map['generatedAt'];
    final evidenceMethodId = map['evidenceMethodId'];
    final generatedAt = generatedAtRaw is String
        ? DateTime.tryParse(generatedAtRaw)
        : null;
    if (content is! String ||
        content.trim().isEmpty ||
        source == null ||
        providerId is! String ||
        modelId is! String ||
        promptVersion == null ||
        generatedAt == null ||
        evidenceMethodId is! String) {
      return null;
    }
    final fallbackReason = map['fallbackReason'];
    return AiInterpretationResponse(
      content: content.trim(),
      source: source,
      providerId: providerId,
      modelId: modelId,
      promptVersion: promptVersion,
      generatedAt: generatedAt,
      evidenceMethodId: evidenceMethodId,
      fallbackReason: fallbackReason is String ? fallbackReason : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'content': content,
    'source': source.id,
    'providerId': providerId,
    'modelId': modelId,
    'promptVersion': promptVersion,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'evidenceMethodId': evidenceMethodId,
    if (fallbackReason != null) 'fallbackReason': fallbackReason,
  };
}
