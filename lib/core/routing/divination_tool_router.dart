enum DivinationTool {
  meihua('meihua', '梅花易数'),
  tarot('tarot', '西方占卜'),
  xiaoliuren('xiaoliuren', '小六壬'),
  ssgw('ssgw', '灵签'),
  dailyHexagram('daily-hexagram', '每日一卦');

  const DivinationTool(this.id, this.label);
  final String id;
  final String label;
}

class DivinationToolSelection {
  const DivinationToolSelection({
    required this.tool,
    required this.reason,
    required this.confidence,
  });

  final DivinationTool tool;
  final String reason;
  final double confidence;
}

class RoutedDivinationDraft {
  RoutedDivinationDraft({required this.question, required this.tool})
    : createdAt = DateTime.now();

  final String question;
  final DivinationTool tool;
  final DateTime createdAt;
}

abstract final class DivinationToolRouter {
  static DivinationToolSelection? select(String rawQuestion) {
    final question = rawQuestion.trim();
    if (question.isEmpty) {
      return null;
    }

    DivinationToolSelection choice(
      DivinationTool tool,
      String reason, [
      double confidence = 0.9,
    ]) => DivinationToolSelection(
      tool: tool,
      reason: reason,
      confidence: confidence,
    );

    if (_containsAny(question, ['梅花易数', '梅花起卦', '梅花'])) {
      return choice(DivinationTool.meihua, '问题明确指定了梅花易数。', 1);
    }
    if (_containsAny(question, ['塔罗', '牌阵', '抽牌'])) {
      return choice(DivinationTool.tarot, '问题明确提到塔罗、牌阵或抽牌。', 1);
    }
    if (_containsAny(question, ['小六壬'])) {
      return choice(DivinationTool.xiaoliuren, '问题明确指定了小六壬。', 1);
    }
    if (_containsAny(question, ['灵签', '求签', '抽签', '签文'])) {
      return choice(DivinationTool.ssgw, '问题属于求签或签文解读。', 1);
    }
    if (_containsAny(question, ['每日一卦', '今日一卦', '今天整体', '今日状态'])) {
      return choice(DivinationTool.dailyHexagram, '问题关注今天的整体状态。', 0.98);
    }

    if (_containsAny(question, [
      '哪里',
      '哪儿',
      '何处',
      '地点',
      '方位',
      '什么时候',
      '何时',
      '时机',
    ])) {
      return choice(
        DivinationTool.meihua,
        '问题重点是地点、方位或时间线索，当前模块中梅花易数的主互变、体用与八卦象意更匹配。',
      );
    }
    if (_containsAny(question, [
      '对方怎么想',
      '对方想法',
      '内心',
      '心理',
      '关系状态',
      '人物特征',
      '什么样的人',
    ])) {
      return choice(DivinationTool.tarot, '问题重点是人物心理、关系状态或人物特征，塔罗牌位更适合分层描述。');
    }
    if (_containsAny(question, ['会不会', '能不能', '是否', '成不成', '顺不顺', '近期结果'])) {
      return choice(
        DivinationTool.xiaoliuren,
        '问题属于短期是否、成败或顺逆判断，小六壬适合快速查看近期趋势。',
        0.85,
      );
    }
    if (_containsAny(question, ['指引', '提醒', '该怎么办', '给我建议', '求个方向'])) {
      return choice(DivinationTool.ssgw, '问题主要寻求综合指引和行动提醒，灵签更符合当前需求。', 0.82);
    }
    if (_containsAny(question, ['今天', '今日', '当天'])) {
      return choice(
        DivinationTool.dailyHexagram,
        '问题限定在当天，优先使用每日一卦查看当日主题。',
        0.8,
      );
    }
    return null;
  }

  static bool _containsAny(String text, List<String> words) =>
      words.any(text.contains);
}
