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

  bool get usesGeneralInterpretation => question.rawText.trim().isEmpty;

  Map<String, dynamic> toJson() {
    final questionJson = question.toJson();
    if (usesGeneralInterpretation) {
      questionJson
        ..['rawText'] = '请综合解读本次$methodLabel结果，说明整体趋势、主要机会、潜在风险和可执行建议。'
        ..['topic'] = 'general'
        ..['intent'] = 'general'
        ..['intentLabel'] = '通用解读';
    }
    return {
      'question': questionJson,
      'evidence': evidence.toJson(),
      'localAnswer': localAnswer,
      'methodLabel': methodLabel,
      'answerStyle': answerStyle,
      'locale': locale,
    };
  }
}

class AiReadingEvidence {
  const AiReadingEvidence({required this.label, required this.explanation});

  final String label;
  final String explanation;

  static AiReadingEvidence? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final label = raw['label'];
    final explanation = raw['explanation'];
    if (label is! String || explanation is! String) return null;
    return AiReadingEvidence(label: label, explanation: explanation);
  }

  Map<String, dynamic> toJson() => {'label': label, 'explanation': explanation};
}

class AiStructuredReading {
  const AiStructuredReading({
    required this.headline,
    required this.plainLanguage,
    required this.evidence,
    required this.risks,
    required this.actions,
    required this.boundary,
    required this.closing,
  });

  final String headline;
  final String plainLanguage;
  final List<AiReadingEvidence> evidence;
  final List<String> risks;
  final List<String> actions;
  final String boundary;
  final String closing;

  static AiStructuredReading? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final headline = raw['headline'];
    final plainLanguage = raw['plainLanguage'];
    if (headline is! String || plainLanguage is! String) return null;
    List<String> strings(String key) => raw[key] is List
        ? (raw[key] as List).whereType<String>().toList(growable: false)
        : const [];
    final evidence = raw['evidence'] is List
        ? (raw['evidence'] as List)
              .map(AiReadingEvidence.tryParse)
              .whereType<AiReadingEvidence>()
              .toList(growable: false)
        : const <AiReadingEvidence>[];
    return AiStructuredReading(
      headline: headline.trim(),
      plainLanguage: plainLanguage.trim(),
      evidence: evidence,
      risks: strings('risks'),
      actions: strings('actions'),
      boundary: raw['boundary'] is String
          ? (raw['boundary'] as String).trim()
          : '',
      closing: raw['closing'] is String
          ? (raw['closing'] as String).trim()
          : '',
    );
  }

  Map<String, dynamic> toJson() => {
    'headline': headline,
    'plainLanguage': plainLanguage,
    'evidence': evidence.map((item) => item.toJson()).toList(),
    'risks': risks,
    'actions': actions,
    'boundary': boundary,
    'closing': closing,
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
    this.reading,
  });

  final String content;
  final AiAnswerSource source;
  final String providerId;
  final String modelId;
  final int promptVersion;
  final DateTime generatedAt;
  final String evidenceMethodId;
  final String? fallbackReason;
  final AiStructuredReading? reading;

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
    final reading = AiStructuredReading.tryParse(map['reading']);
    return AiInterpretationResponse(
      content: content.trim(),
      source: source,
      providerId: providerId,
      modelId: modelId,
      promptVersion: promptVersion,
      generatedAt: generatedAt,
      evidenceMethodId: evidenceMethodId,
      fallbackReason: fallbackReason is String ? fallbackReason : null,
      reading: reading,
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
    if (reading != null) 'reading': reading!.toJson(),
  };
}
