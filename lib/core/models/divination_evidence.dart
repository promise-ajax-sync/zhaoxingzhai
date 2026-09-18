class DivinationEvidenceItem {
  const DivinationEvidenceItem({
    required this.id,
    required this.label,
    required this.detail,
  });

  final String id;
  final String label;
  final String detail;

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'detail': detail};

  static DivinationEvidenceItem? tryParse(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(raw);
    if (map['id'] is! String ||
        map['label'] is! String ||
        map['detail'] is! String) {
      return null;
    }
    return DivinationEvidenceItem(
      id: map['id'] as String,
      label: map['label'] as String,
      detail: map['detail'] as String,
    );
  }
}

class DivinationEvidence {
  const DivinationEvidence({
    required this.methodId,
    required this.version,
    required this.calculationFacts,
    required this.supportingEvidence,
    required this.counterEvidence,
    required this.limitations,
    required this.summary,
  });

  final String methodId;
  final int version;
  final List<DivinationEvidenceItem> calculationFacts;
  final List<DivinationEvidenceItem> supportingEvidence;
  final List<DivinationEvidenceItem> counterEvidence;
  final List<DivinationEvidenceItem> limitations;
  final String summary;

  Map<String, dynamic> toJson() => {
    'methodId': methodId,
    'version': version,
    'calculationFacts': calculationFacts.map((item) => item.toJson()).toList(),
    'supportingEvidence': supportingEvidence
        .map((item) => item.toJson())
        .toList(),
    'counterEvidence': counterEvidence.map((item) => item.toJson()).toList(),
    'limitations': limitations.map((item) => item.toJson()).toList(),
    'summary': summary,
  };

  static DivinationEvidence? tryParse(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(raw);
    final methodId = map['methodId'];
    final version = (map['version'] as num?)?.toInt();
    final summary = map['summary'];
    if (methodId is! String || version == null || summary is! String) {
      return null;
    }
    List<DivinationEvidenceItem> items(String key) => map[key] is List
        ? (map[key] as List)
              .map(DivinationEvidenceItem.tryParse)
              .whereType<DivinationEvidenceItem>()
              .toList(growable: false)
        : const [];
    return DivinationEvidence(
      methodId: methodId,
      version: version,
      calculationFacts: items('calculationFacts'),
      supportingEvidence: items('supportingEvidence'),
      counterEvidence: items('counterEvidence'),
      limitations: items('limitations'),
      summary: summary,
    );
  }
}
