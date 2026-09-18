enum DivinationQuestionIntent {
  yesNo('yes_no', '是否判断'),
  timing('timing', '时间时机'),
  location('location', '地点场景'),
  person('person', '人物特征'),
  cause('cause', '原因阻力'),
  trend('trend', '发展趋势'),
  action('action', '行动建议'),
  risk('risk', '风险提醒'),
  general('general', '综合分析');

  const DivinationQuestionIntent(this.id, this.label);
  final String id;
  final String label;
}

class DivinationQuestion {
  const DivinationQuestion({
    required this.rawText,
    required this.topic,
    required this.intent,
  });

  final String rawText;
  final String topic;
  final DivinationQuestionIntent intent;

  static String inferTopic(String rawText) {
    final text = rawText.trim();
    if (['感情', '对象', '恋爱', '婚姻', '复合', '桃花', '对方', '关系'].any(text.contains)) {
      return 'relationship';
    }
    if (['事业', '工作', '职场', '合作', '项目', '创业'].any(text.contains)) {
      return 'career';
    }
    if (['财运', '财富', '收入', '投资', '赚钱', '经营'].any(text.contains)) {
      return 'wealth';
    }
    if (['健康', '身体', '疾病', '恢复', '症状'].any(text.contains)) {
      return 'health';
    }
    if (['学业', '考试', '学习', '升学', '考证'].any(text.contains)) {
      return 'study';
    }
    return 'general';
  }

  factory DivinationQuestion.parse(String rawText, {String topic = 'general'}) {
    final text = rawText.trim();
    bool containsAny(List<String> words) => words.any(text.contains);
    final intent = switch (text) {
      _ when containsAny(['哪里', '哪儿', '何处', '地点', '地方', '方位']) =>
        DivinationQuestionIntent.location,
      _ when containsAny(['什么时候', '何时', '多久', '几月', '哪天', '时间', '时机']) =>
        DivinationQuestionIntent.timing,
      _
          when containsAny([
            '什么样的人',
            '什么样',
            '特征',
            '性格',
            '对方是谁',
            '对方内心',
            '内心怎么想',
            '对方想法',
            '对方态度',
            '人物',
          ]) =>
        DivinationQuestionIntent.person,
      _ when containsAny(['为什么', '为何', '原因', '阻力', '问题出在']) =>
        DivinationQuestionIntent.cause,
      _ when containsAny(['风险', '危险', '注意什么', '隐患']) =>
        DivinationQuestionIntent.risk,
      _ when containsAny(['怎么办', '怎么做', '如何做', '应该怎么', '建议', '要不要主动']) =>
        DivinationQuestionIntent.action,
      _ when containsAny(['发展', '走向', '结果', '未来', '后来', '趋势']) =>
        DivinationQuestionIntent.trend,
      _ when containsAny(['是否', '会不会', '能不能', '可不可以', '有没有', '要不要']) =>
        DivinationQuestionIntent.yesNo,
      _ => DivinationQuestionIntent.general,
    };
    return DivinationQuestion(rawText: text, topic: topic, intent: intent);
  }

  Map<String, dynamic> toJson() => {
    'rawText': rawText,
    'topic': topic,
    'intent': intent.id,
    'intentLabel': intent.label,
  };
}
