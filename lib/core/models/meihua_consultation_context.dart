class MeihuaConsultationContext {
  const MeihuaConsultationContext({
    this.question = '',
    this.observation = '',
    this.soundSource = '',
    this.directionNote = '',
    this.topic = 'general',
  });

  final String question;
  final String observation;
  final String soundSource;
  final String directionNote;
  final String topic;

  String get topicLabel => switch (topic) {
    'career' => '事业工作',
    'relationship' => '感情关系',
    'wealth' => '财运经营',
    'health' => '健康状态',
    'study' => '学业考试',
    _ => '综合事项',
  };

  bool get isEmpty =>
      question.isEmpty &&
      observation.isEmpty &&
      soundSource.isEmpty &&
      directionNote.isEmpty &&
      topic == 'general';

  Map<String, dynamic> toJson() => {
    if (question.isNotEmpty) 'question': question,
    if (observation.isNotEmpty) 'observation': observation,
    if (soundSource.isNotEmpty) 'soundSource': soundSource,
    if (directionNote.isNotEmpty) 'directionNote': directionNote,
    'topic': topic,
  };

  static MeihuaConsultationContext? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    String read(String key) => map[key] is String ? (map[key] as String) : '';
    final result = MeihuaConsultationContext(
      question: read('question'),
      observation: read('observation'),
      soundSource: read('soundSource'),
      directionNote: read('directionNote'),
      topic: read('topic').isEmpty ? 'general' : read('topic'),
    );
    return result.isEmpty ? null : result;
  }
}
