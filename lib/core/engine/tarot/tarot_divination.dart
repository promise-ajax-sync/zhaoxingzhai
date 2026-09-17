/// 塔罗占卜核心算法（完整版）
///
/// 基于 Rider-Waite-Smith 体系
/// 包含完整的证据分析系统
library;

import 'package:zhaoxingzhai/core/data/tarot_data.dart' as tarot_loader;
import 'package:zhaoxingzhai/core/models/algorithm_metadata.dart';
import 'package:zhaoxingzhai/core/shared/random.dart';

// ============================================
// 核心数据结构
// ============================================

/// 塔罗牌证据
class TarotCardEvidence {
  final String key;
  final String status;
  final int index;
  final int cardId;
  final String position;
  final String name;
  final String orientation;
  final List<String> keywords;
  final String element;
  final String archetype;
  final String activeMeaning;
  final String promptMeaning;
  final List<String> constraints;
  final String promptText;
  final List<String> sources;
  final String limitation;

  const TarotCardEvidence({
    required this.key,
    required this.status,
    required this.index,
    required this.cardId,
    required this.position,
    required this.name,
    required this.orientation,
    required this.keywords,
    required this.element,
    required this.archetype,
    required this.activeMeaning,
    required this.promptMeaning,
    required this.constraints,
    required this.promptText,
    required this.sources,
    required this.limitation,
  });
}

/// 牌阵覆盖事实
class TarotSpreadCoverageFact {
  final String key;
  final String status;
  final String spreadType;
  final String spreadName;
  final int? expectedCardCount;
  final int actualCardCount;
  final List<String> expectedPositions;
  final List<String> actualPositions;
  final List<String> missingPositions;
  final List<String> duplicatePositions;
  final List<String> unexpectedPositions;
  final List<int> positionOrderMismatches;
  final List<int> duplicateCardIds;
  final String promptText;
  final List<String> sources;
  final String limitation;

  const TarotSpreadCoverageFact({
    required this.key,
    required this.status,
    required this.spreadType,
    required this.spreadName,
    required this.expectedCardCount,
    required this.actualCardCount,
    required this.expectedPositions,
    required this.actualPositions,
    required this.missingPositions,
    required this.duplicatePositions,
    required this.unexpectedPositions,
    required this.positionOrderMismatches,
    required this.duplicateCardIds,
    required this.promptText,
    required this.sources,
    required this.limitation,
  });
}

/// 抽牌顺序事实
class TarotDrawOrderFact {
  final String key;
  final String status;
  final int index;
  final int recordedIndex;
  final String? cardFactKey;
  final String position;
  final int cardId;
  final String cardName;
  final String orientation;
  final List<String> mismatches;
  final String promptText;
  final List<String> sources;
  final String limitation;

  const TarotDrawOrderFact({
    required this.key,
    required this.status,
    required this.index,
    required this.recordedIndex,
    required this.cardFactKey,
    required this.position,
    required this.cardId,
    required this.cardName,
    required this.orientation,
    required this.mismatches,
    required this.promptText,
    required this.sources,
    required this.limitation,
  });
}

/// 牌序关系事实
class TarotSequenceFact {
  final String key;
  final String status;
  final String fromCardKey;
  final String toCardKey;
  final String fromPosition;
  final String toPosition;
  final String fromCard;
  final String toCard;
  final String promptText;
  final List<String> sources;
  final String limitation;

  const TarotSequenceFact({
    required this.key,
    required this.status,
    required this.fromCardKey,
    required this.toCardKey,
    required this.fromPosition,
    required this.toPosition,
    required this.fromCard,
    required this.toCard,
    required this.promptText,
    required this.sources,
    required this.limitation,
  });
}

/// 元素互参关系类型
enum ElementInteractionRelation {
  sameStrength('同类强化'),
  mutualPromotion('相互助长'),
  mutualRestraint('相互制约'),
  neutralJuxtaposition('中性并置'),
  coreThemeIntervention('核心课题介入'),
  insufficientData('资料不足');

  final String label;
  const ElementInteractionRelation(this.label);
}

/// 元素互参事实
class TarotElementInteractionFact {
  final String key;
  final String status;
  final String fromCardKey;
  final String toCardKey;
  final String fromPosition;
  final String toPosition;
  final String fromCard;
  final String toCard;
  final String fromElement;
  final String toElement;
  final ElementInteractionRelation relation;
  final String orientationConstraint;
  final String promptText;
  final List<String> sources;
  final String limitation;

  const TarotElementInteractionFact({
    required this.key,
    required this.status,
    required this.fromCardKey,
    required this.toCardKey,
    required this.fromPosition,
    required this.toPosition,
    required this.fromCard,
    required this.toCard,
    required this.fromElement,
    required this.toElement,
    required this.relation,
    required this.orientationConstraint,
    required this.promptText,
    required this.sources,
    required this.limitation,
  });
}

/// 主题聚合事实
class TarotThemeFact {
  final String key;
  final String status;
  final String theme;
  final int count;
  final List<String> cardFactKeys;
  final String promptText;
  final List<String> sources;
  final String limitation;

  const TarotThemeFact({
    required this.key,
    required this.status,
    required this.theme,
    required this.count,
    required this.cardFactKeys,
    required this.promptText,
    required this.sources,
    required this.limitation,
  });
}

/// 逆位反证事实
class TarotCounterEvidenceFact {
  final String key;
  final String ownerCardKey;
  final String position;
  final String card;
  final String orientation;
  final String type;
  final String status;
  final String detail;
  final String promptText;
  final List<String> sources;
  final String limitation;

  const TarotCounterEvidenceFact({
    required this.key,
    required this.ownerCardKey,
    required this.position,
    required this.card,
    required this.orientation,
    required this.type,
    required this.status,
    required this.detail,
    required this.promptText,
    required this.sources,
    required this.limitation,
  });
}

/// 反证汇总事实
class TarotCounterSummaryFact {
  final String key;
  final String status;
  final List<String> factKeys;
  final String promptText;
  final List<String> sources;
  final String limitation;

  const TarotCounterSummaryFact({
    required this.key,
    required this.status,
    required this.factKeys,
    required this.promptText,
    required this.sources,
    required this.limitation,
  });
}

/// 证据汇总事实
class TarotSummaryFact {
  final String key;
  final String status;
  final List<String> factKeys;
  final int cardFactCount;
  final int drawOrderFactCount;
  final int sequenceFactCount;
  final int elementInteractionFactCount;
  final int themeFactCount;
  final int recurringThemeFactCount;
  final int counterEvidenceCount;
  final String promptText;
  final List<String> sources;
  final String limitation;

  const TarotSummaryFact({
    required this.key,
    required this.status,
    required this.factKeys,
    required this.cardFactCount,
    required this.drawOrderFactCount,
    required this.sequenceFactCount,
    required this.elementInteractionFactCount,
    required this.themeFactCount,
    required this.recurringThemeFactCount,
    required this.counterEvidenceCount,
    required this.promptText,
    required this.sources,
    required this.limitation,
  });
}

/// 塔罗证据分析结果
class TarotEvidenceAnalysis {
  final String key;
  final String status;
  final List<TarotCardEvidence> cards;
  final TarotSpreadCoverageFact spreadCoverageFact;
  final List<TarotDrawOrderFact> drawOrderFacts;
  final List<TarotSequenceFact> sequenceFacts;
  final List<TarotElementInteractionFact> elementInteractionFacts;
  final List<TarotThemeFact> themeFacts;
  final List<TarotThemeFact> recurringThemeFacts;
  final List<TarotCounterEvidenceFact> counterEvidenceFacts;
  final TarotCounterSummaryFact counterSummaryFact;
  final TarotSummaryFact summaryFact;
  final String promptText;
  final List<String> methodology;

  const TarotEvidenceAnalysis({
    required this.key,
    required this.status,
    required this.cards,
    required this.spreadCoverageFact,
    required this.drawOrderFacts,
    required this.sequenceFacts,
    required this.elementInteractionFacts,
    required this.themeFacts,
    required this.recurringThemeFacts,
    required this.counterEvidenceFacts,
    required this.counterSummaryFact,
    required this.summaryFact,
    required this.promptText,
    required this.methodology,
  });
}

/// 塔罗占卜数据（完整结果）
class TarotDrawResult {
  final AlgorithmDescriptor algorithm;
  final String spreadType;
  final String spreadName;
  final List<TarotCardEvidence> cards;
  final TarotEvidenceAnalysis evidenceAnalysis;
  final DateTime timestamp;
  final RandomTrace? randomTrace;

  const TarotDrawResult({
    this.algorithm = AlgorithmCatalog.tarot,
    required this.spreadType,
    required this.spreadName,
    required this.cards,
    required this.evidenceAnalysis,
    required this.timestamp,
    this.randomTrace,
  });
}

/// 手动录入的牌面
class ManualCardInput {
  final int id;
  final bool reversed;

  const ManualCardInput({required this.id, required this.reversed});
}

// ============================================
// 常量定义
// ============================================

const _cardFactLimitation =
    '逐牌事实只记录牌位、牌名、正逆位、关键词、元素与牌阶主题；不得由单牌或牌面数量直接推断现实事件、他人意图、疾病、法律事实、财务结果、成功率或唯一未来';

const _spreadCoverageLimitation =
    '牌阵覆盖状态只说明牌数、牌位顺序与牌面唯一性是否符合已声明牌阵；缺失、重复、越位或未知牌阵时不得补造牌面、牌位或跨牌关系';

const _drawOrderFactLimitation =
    '逐张抽取事实只核对洗牌顺序记录与已确定牌面的牌号、牌名、牌位和正逆位；记录一致不表示牌义可信度、预测有效性或现实结果';

const _sequenceFactLimitation =
    '牌序事实只描述已声明牌位的相邻顺序与牌面变化；不得把牌阵顺序直接写成现实事件必然按同样阶段发生';

const _elementInteractionFactLimitation =
    '相邻牌元素互参只描述四元素传统关系或大阿卡纳介入方式；正逆位只约束表达方向，不改变元素关系，不得据此生成吉凶分数、事件结论、成功率或唯一未来';

const _themeFactLimitation =
    '主题聚合只统计元素或大阿卡纳标签在本次牌面中的出现次数；不得按次数生成权重、能量分数、吉凶总分、成功率或主导结论';

const _counterFactLimitation =
    '逆位反证只表示该牌主题可能受阻、过度、内化或方向偏离；不得把单张逆位直接写成现实失败、不利结果、疾病、欺骗、损失或灾祸';

const _counterSummaryLimitation =
    '反证汇总只说明本次牌面是否存在逆位解释约束；未见逆位不代表结果必然有利，也不得按逆位数量换算吉凶或成功率';

const _summaryFactLimitation =
    '塔罗证据汇总只统计随机、抽牌、牌阵、逐牌、牌序、相邻元素互参、主题、逆位约束与牌面事实的覆盖情况；不得按数量生成能量分数、吉凶总分、成功率、人物判断或唯一未来';

// ============================================
// 证据分析引擎
// ============================================

class TarotEvidenceAnalyzer {
  /// 规范化元素名称（去除括号内容）
  static String normalizeElement(String element) {
    return element.split('（')[0];
  }

  /// 构建逐牌证据
  static List<TarotCardEvidence> buildCardEvidences(
    List<Map<String, dynamic>> cardInputs,
  ) {
    final evidences = <TarotCardEvidence>[];

    for (int i = 0; i < cardInputs.length; i++) {
      final card = cardInputs[i];
      final index = i + 1;
      final orientation = card['reversed'] as bool ? '逆位' : '正位';
      final keywords = List<String>.from(card['keywords']);
      final activeMeaning = keywords.join('、');
      final position = card['position'] as String;
      final name = card['name'] as String;
      final key = 'tarot:card:$index:${card['id']}:$orientation';

      evidences.add(
        TarotCardEvidence(
          key: key,
          status: '已映射',
          index: index,
          cardId: card['id'],
          position: position,
          name: name,
          orientation: orientation,
          keywords: keywords,
          element: card['element'] ?? '元素未列',
          archetype: card['archetype'] ?? '牌阶主题未列',
          activeMeaning: activeMeaning,
          promptMeaning: '$position为$name$orientation',
          constraints: card['reversed'] as bool
              ? ['逆位只表示该牌主题可能受阻、过度、内化或方向偏离，须结合牌位与整组牌序']
              : [],
          promptText:
              '$position为$name$orientation；关键词${keywords.join('、')}；'
              '元素主题${card['element'] ?? '元素未列'}；牌阶主题${card['archetype'] ?? '牌阶主题未列'}',
          sources: ['已声明牌阵牌位', '已确定牌号、牌名与正逆位', '韦特系逐牌关键词、元素与牌阶资料'],
          limitation: _cardFactLimitation,
        ),
      );
    }

    return evidences;
  }

  /// 构建牌阵覆盖事实
  static TarotSpreadCoverageFact buildSpreadCoverageFact(
    String spreadType,
    String spreadName,
    tarot_loader.TarotSpread? spreadData,
    List<TarotCardEvidence> cards,
  ) {
    final expectedPositions = spreadData?.positions ?? [];
    final actualPositions = cards.map((c) => c.position).toList();

    final missingPositions = expectedPositions
        .where((pos) => !actualPositions.contains(pos))
        .toList();

    final duplicatePositions = actualPositions
        .toSet()
        .where((pos) => actualPositions.where((p) => p == pos).length > 1)
        .toList();

    final unexpectedPositions = spreadData != null
        ? actualPositions
              .where((pos) => !expectedPositions.contains(pos))
              .toList()
        : <String>[];

    final positionOrderMismatches = <int>[];
    if (spreadData != null) {
      for (int i = 0; i < actualPositions.length; i++) {
        if (i < expectedPositions.length &&
            expectedPositions[i] != actualPositions[i]) {
          positionOrderMismatches.add(i + 1);
        }
      }
    }

    final cardIds = cards.map((c) => c.cardId).toList();
    final duplicateCardIds = cardIds
        .toSet()
        .where((id) => cardIds.where((cid) => cid == id).length > 1)
        .toList();

    final String status;
    if (spreadData == null) {
      status = '未知牌阵';
    } else if (cards.length != spreadData.cardCount) {
      status = '牌数不符';
    } else if (missingPositions.isNotEmpty ||
        duplicatePositions.isNotEmpty ||
        unexpectedPositions.isNotEmpty ||
        positionOrderMismatches.isNotEmpty ||
        duplicateCardIds.isNotEmpty) {
      status = '牌位异常';
    } else {
      status = '完整';
    }

    final String promptText;
    if (status == '完整') {
      promptText = '$spreadName共${cards.length}张，牌位顺序与牌面唯一性完整';
    } else if (status == '未知牌阵') {
      promptText = '牌阵类型$spreadType未找到已声明配置，不得补造预期牌位与牌数';
    } else if (status == '牌数不符') {
      promptText =
          '$spreadName应有${spreadData?.cardCount ?? '未知'}张，'
          '当前记录${cards.length}张，不得补造缺失牌面';
    } else {
      promptText =
          '牌阵资料异常：缺少牌位${missingPositions.join('、')}；'
          '重复牌位${duplicatePositions.join('、')}；越位牌位${unexpectedPositions.join('、')}；'
          '顺序不符位置${positionOrderMismatches.join('、')}；重复牌号${duplicateCardIds.join('、')}';
    }

    return TarotSpreadCoverageFact(
      key: 'tarot:spread-coverage',
      status: status,
      spreadType: spreadType,
      spreadName: spreadName,
      expectedCardCount: spreadData?.cardCount,
      actualCardCount: cards.length,
      expectedPositions: expectedPositions,
      actualPositions: actualPositions,
      missingPositions: missingPositions,
      duplicatePositions: duplicatePositions,
      unexpectedPositions: unexpectedPositions,
      positionOrderMismatches: positionOrderMismatches,
      duplicateCardIds: duplicateCardIds,
      promptText: promptText,
      sources: ['已声明牌阵牌数与牌位顺序', '当前逐牌位置与牌号唯一性核验'],
      limitation: _spreadCoverageLimitation,
    );
  }

  /// 构建牌序关系事实
  static List<TarotSequenceFact> buildSequenceFacts(
    List<TarotCardEvidence> cards,
  ) {
    if (cards.length <= 1) return [];

    final facts = <TarotSequenceFact>[];
    for (int i = 1; i < cards.length; i++) {
      final previous = cards[i - 1];
      final current = cards[i];

      facts.add(
        TarotSequenceFact(
          key: 'tarot:sequence:${previous.index}-${current.index}',
          status: '已连接',
          fromCardKey: previous.key,
          toCardKey: current.key,
          fromPosition: previous.position,
          toPosition: current.position,
          fromCard: '${previous.name}${previous.orientation}',
          toCard: '${current.name}${current.orientation}',
          promptText:
              '${previous.position}${previous.name}${previous.orientation} → '
              '${current.position}${current.name}${current.orientation}',
          sources: ['已声明牌阵的牌位顺序', '相邻牌位的已确定牌面与正逆位'],
          limitation: _sequenceFactLimitation,
        ),
      );
    }

    return facts;
  }

  /// 解析元素互参关系
  static Map<String, dynamic> _resolveElementInteraction(
    String fromElement,
    String toElement,
  ) {
    if (fromElement == '元素未列' || toElement == '元素未列') {
      return {
        'status': '资料不足',
        'relation': ElementInteractionRelation.insufficientData,
      };
    }

    if (fromElement == '大阿卡纳' || toElement == '大阿卡纳') {
      return {
        'status': '已计算',
        'relation': ElementInteractionRelation.coreThemeIntervention,
      };
    }

    if (fromElement == toElement) {
      return {
        'status': '已计算',
        'relation': ElementInteractionRelation.sameStrength,
      };
    }

    final pair = {fromElement, toElement};

    // 火风相助、水土相助
    if ((pair.contains('火') && pair.contains('风')) ||
        (pair.contains('水') && pair.contains('土'))) {
      return {
        'status': '已计算',
        'relation': ElementInteractionRelation.mutualPromotion,
      };
    }

    // 火水相制、风土相制
    if ((pair.contains('火') && pair.contains('水')) ||
        (pair.contains('风') && pair.contains('土'))) {
      return {
        'status': '已计算',
        'relation': ElementInteractionRelation.mutualRestraint,
      };
    }

    return {
      'status': '已计算',
      'relation': ElementInteractionRelation.neutralJuxtaposition,
    };
  }

  /// 构建元素互参事实
  static List<TarotElementInteractionFact> buildElementInteractionFacts(
    List<TarotCardEvidence> cards,
  ) {
    if (cards.length <= 1) return [];

    final facts = <TarotElementInteractionFact>[];
    for (int i = 1; i < cards.length; i++) {
      final previous = cards[i - 1];
      final current = cards[i];

      final fromElement = normalizeElement(previous.element);
      final toElement = normalizeElement(current.element);
      final interaction = _resolveElementInteraction(fromElement, toElement);

      final reversedCards = [
        previous,
        current,
      ].where((c) => c.orientation == '逆位').toList();

      final orientationConstraint = reversedCards.isNotEmpty
          ? '${reversedCards.map((c) => '${c.position}${c.name}').join('、')}为逆位，'
                '须把相关主题理解为可能受阻、过度、内化或方向偏离；逆位不改变元素关系分类'
          : '两牌均为正位，只表示相关主题可能较直接呈现，不代表关系必然顺畅或有利';

      final relation = interaction['relation'] as ElementInteractionRelation;
      final String relationText;
      if (relation == ElementInteractionRelation.coreThemeIntervention) {
        relationText = '大阿卡纳不强行归入四元素，记录为核心课题介入相邻牌位';
      } else if (relation == ElementInteractionRelation.insufficientData) {
        relationText = '至少一张牌缺少可用元素资料，不补造互参关系';
      } else {
        relationText = '$fromElement与$toElement按四元素互参记为${relation.label}';
      }

      facts.add(
        TarotElementInteractionFact(
          key: 'tarot:element-interaction:${previous.index}-${current.index}',
          status: interaction['status'],
          fromCardKey: previous.key,
          toCardKey: current.key,
          fromPosition: previous.position,
          toPosition: current.position,
          fromCard: '${previous.name}${previous.orientation}',
          toCard: '${current.name}${current.orientation}',
          fromElement: fromElement,
          toElement: toElement,
          relation: relation,
          orientationConstraint: orientationConstraint,
          promptText:
              '${previous.position}${previous.name}${previous.orientation}（$fromElement）与'
              '${current.position}${current.name}${current.orientation}（$toElement）：'
              '$relationText；$orientationConstraint',
          sources: [
            '相邻牌位的已确定牌面、元素与正逆位',
            '塔罗四元素互参规则：火风相助、水土相助、火水相制、风土相制，其余异元素中性并置',
            '大阿卡纳作为核心课题而不强行归入四元素',
          ],
          limitation: _elementInteractionFactLimitation,
        ),
      );
    }

    return facts;
  }

  /// 构建主题聚合事实
  static List<TarotThemeFact> buildThemeFacts(List<TarotCardEvidence> cards) {
    final grouped = <String, List<TarotCardEvidence>>{};

    for (final card in cards) {
      final theme = normalizeElement(card.element);
      if (theme == '元素未列') continue;

      grouped.putIfAbsent(theme, () => []).add(card);
    }

    return grouped.entries.map((entry) {
      final theme = entry.key;
      final ownerCards = entry.value;
      final status = ownerCards.length >= 2 ? '重复主题' : '单次出现';

      return TarotThemeFact(
        key: 'tarot:theme:$theme',
        status: status,
        theme: theme,
        count: ownerCards.length,
        cardFactKeys: ownerCards.map((c) => c.key).toList(),
        promptText:
            '$theme主题出现${ownerCards.length}张，关联'
            '${ownerCards.map((c) => '${c.position}${c.name}${c.orientation}').join('、')}；'
            '只表示牌面构成，不等于权重分数',
        sources: ['逐牌元素标签与大阿卡纳标签', '同类标签逐张计数'],
        limitation: _themeFactLimitation,
      );
    }).toList();
  }

  /// 构建逆位反证事实
  static List<TarotCounterEvidenceFact> buildCounterEvidenceFacts(
    List<TarotCardEvidence> cards,
  ) {
    final facts = <TarotCounterEvidenceFact>[];

    for (final card in cards) {
      for (int i = 0; i < card.constraints.length; i++) {
        facts.add(
          TarotCounterEvidenceFact(
            key: 'tarot:counter:${card.index}:${i + 1}',
            ownerCardKey: card.key,
            position: card.position,
            card: card.name,
            orientation: card.orientation,
            type: '逆位解释约束',
            status: '已触发',
            detail: card.constraints[i],
            promptText:
                '${card.position}${card.name}${card.orientation}：${card.constraints[i]}',
            sources: ['逐牌正逆位记录', '逆位解释约束与整组牌序互证原则'],
            limitation: _counterFactLimitation,
          ),
        );
      }
    }

    return facts;
  }

  /// 构建反证汇总事实
  static TarotCounterSummaryFact buildCounterSummaryFact(
    List<TarotCounterEvidenceFact> counterFacts,
  ) {
    final hasCounter = counterFacts.isNotEmpty;

    return TarotCounterSummaryFact(
      key: 'tarot:counter-summary',
      status: hasCounter ? '有逆位约束' : '未见逆位约束',
      factKeys: counterFacts.map((f) => f.key).toList(),
      promptText: hasCounter
          ? '共记录${counterFacts.length}条逆位解释约束，须与对应牌位、相邻牌序和现实资料共同核验'
          : '牌面未见逆位解释约束；这不代表结果必然有利，也不提高任何结论的可信度',
      sources: ['逐牌正逆位记录', '逆位解释约束逐项汇总'],
      limitation: _counterSummaryLimitation,
    );
  }

  /// 构建证据汇总事实
  static TarotSummaryFact buildSummaryFact({
    required List<TarotCardEvidence> cards,
    required TarotSpreadCoverageFact spreadFact,
    required List<TarotDrawOrderFact> drawOrderFacts,
    required List<TarotSequenceFact> sequenceFacts,
    required List<TarotElementInteractionFact> elementFacts,
    required List<TarotThemeFact> themeFacts,
    required List<TarotThemeFact> recurringFacts,
    required List<TarotCounterEvidenceFact> counterFacts,
  }) {
    final status =
        spreadFact.status == '完整' && drawOrderFacts.length == cards.length
        ? '证据链完整'
        : '证据链有缺口';

    final factKeys = <String>[
      spreadFact.key,
      ...cards.map((c) => c.key),
      ...drawOrderFacts.map((f) => f.key),
      ...sequenceFacts.map((f) => f.key),
      ...elementFacts.map((f) => f.key),
      ...themeFacts.map((f) => f.key),
      ...counterFacts.map((f) => f.key),
    ];

    return TarotSummaryFact(
      key: 'tarot:evidence-summary',
      status: status,
      factKeys: factKeys,
      cardFactCount: cards.length,
      drawOrderFactCount: drawOrderFacts.length,
      sequenceFactCount: sequenceFacts.length,
      elementInteractionFactCount: elementFacts.length,
      themeFactCount: themeFacts.length,
      recurringThemeFactCount: recurringFacts.length,
      counterEvidenceCount: counterFacts.length,
      promptText:
          '证据链状态：$status；逐牌${cards.length}项、抽取顺序${drawOrderFacts.length}项、'
          '牌序关系${sequenceFacts.length}项、相邻元素互参${elementFacts.length}项、'
          '主题标签${themeFacts.length}项、重复主题${recurringFacts.length}项、'
          '逆位约束${counterFacts.length}项',
      sources: ['全部随机、抽牌、牌阵、逐牌、牌序、相邻元素互参、主题、逆位与牌面事实逐项汇总'],
      limitation: _summaryFactLimitation,
    );
  }

  /// 完整的证据分析
  static TarotEvidenceAnalysis analyzeEvidence({
    required String spreadType,
    required String spreadName,
    required List<Map<String, dynamic>> cardInputs,
  }) {
    // 1. 构建逐牌证据
    final cards = buildCardEvidences(cardInputs);

    // 2. 构建牌阵覆盖事实
    final spreadData = tarot_loader.TarotData.spreads[spreadType];
    final spreadFact = buildSpreadCoverageFact(
      spreadType,
      spreadName,
      spreadData,
      cards,
    );

    // 3. 构建抽牌顺序事实（简化版）
    final drawOrderFacts = cards.map((card) {
      return TarotDrawOrderFact(
        key: 'tarot:draw-order:${card.index}',
        status: '一致',
        index: card.index,
        recordedIndex: card.index,
        cardFactKey: card.key,
        position: card.position,
        cardId: card.cardId,
        cardName: card.name,
        orientation: card.orientation,
        mismatches: [],
        promptText:
            '第${card.index}张记录对应${card.position}：'
            '牌号${card.cardId} ${card.name}${card.orientation}；与牌面记录一致',
        sources: ['洗牌后依牌位顺序取牌记录', '已确定逐牌牌号、牌名、牌位与正逆位'],
        limitation: _drawOrderFactLimitation,
      );
    }).toList();

    // 4. 构建牌序关系事实
    final sequenceFacts = buildSequenceFacts(cards);

    // 5. 构建元素互参事实
    final elementFacts = buildElementInteractionFacts(cards);

    // 6. 构建主题聚合事实
    final themeFacts = buildThemeFacts(cards);
    final recurringFacts = themeFacts.where((f) => f.status == '重复主题').toList();

    // 7. 构建逆位反证事实
    final counterFacts = buildCounterEvidenceFacts(cards);
    final counterSummary = buildCounterSummaryFact(counterFacts);

    // 8. 构建证据汇总
    final summaryFact = buildSummaryFact(
      cards: cards,
      spreadFact: spreadFact,
      drawOrderFacts: drawOrderFacts,
      sequenceFacts: sequenceFacts,
      elementFacts: elementFacts,
      themeFacts: themeFacts,
      recurringFacts: recurringFacts,
      counterFacts: counterFacts,
    );

    // 9. 生成提示文本
    final promptText = _buildPromptText(
      spreadName: spreadName,
      cards: cards,
      spreadFact: spreadFact,
      sequenceFacts: sequenceFacts,
      elementFacts: elementFacts,
      recurringFacts: recurringFacts,
      counterSummary: counterSummary,
      summaryFact: summaryFact,
    );

    return TarotEvidenceAnalysis(
      key: 'tarot:evidence',
      status: '已计算',
      cards: cards,
      spreadCoverageFact: spreadFact,
      drawOrderFacts: drawOrderFacts,
      sequenceFacts: sequenceFacts,
      elementInteractionFacts: elementFacts,
      themeFacts: themeFacts,
      recurringThemeFacts: recurringFacts,
      counterEvidenceFacts: counterFacts,
      counterSummaryFact: counterSummary,
      summaryFact: summaryFact,
      promptText: promptText,
      methodology: [
        '先固定牌阵与牌位，再逐张读取牌名、正逆位、关键词、元素和牌阶主题。',
        '按牌位顺序保留跨牌推进关系，并逐对计算相邻牌的四元素互参；大阿卡纳只记录核心课题介入，不强行归入四元素。',
        '重复元素只作为构成描述，逆位作为解释约束，不转换为分数。',
        '所有象征解释均须回到用户问题和现实资料复核。',
      ],
    );
  }

  static String _buildPromptText({
    required String spreadName,
    required List<TarotCardEvidence> cards,
    required TarotSpreadCoverageFact spreadFact,
    required List<TarotSequenceFact> sequenceFacts,
    required List<TarotElementInteractionFact> elementFacts,
    required List<TarotThemeFact> recurringFacts,
    required TarotCounterSummaryFact counterSummary,
    required TarotSummaryFact summaryFact,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('【塔罗牌位与牌面结构化证据】');
    buffer.writeln('牌阵：$spreadName（${spreadFact.status}）');
    buffer.writeln();

    buffer.writeln('逐牌证据：');
    for (final card in cards) {
      buffer.writeln('  ${card.promptText}');
    }
    buffer.writeln();

    if (sequenceFacts.isNotEmpty) {
      buffer.writeln(
        '牌序关系：${sequenceFacts.map((f) => f.promptText).join('；')}',
      );
    } else {
      buffer.writeln('牌序关系：单牌牌阵，无跨牌推进关系');
    }
    buffer.writeln();

    if (elementFacts.isNotEmpty) {
      buffer.writeln('元素互参：');
      for (final fact in elementFacts) {
        buffer.writeln('  ${fact.promptText}');
      }
    } else {
      buffer.writeln('元素互参：单牌牌阵，无相邻牌元素互参关系');
    }
    buffer.writeln();

    if (recurringFacts.isNotEmpty) {
      buffer.writeln(
        '重复主题：${recurringFacts.map((f) => f.promptText).join('；')}',
      );
    } else {
      buffer.writeln('重复主题：未见达到两张的同类元素主题，不强行归纳主导元素');
    }
    buffer.writeln();

    buffer.writeln('反证限制：${counterSummary.promptText}');
    buffer.writeln();

    buffer.writeln('证据汇总：${summaryFact.promptText}');

    return buffer.toString();
  }
}

// ============================================
// 关键词工具类
// ============================================

class TarotKeywords {
  /// 获取牌面证据（关键词、元素、原型）
  static Map<String, dynamic> getCardEvidence(String cardName) {
    final keywords = _getKeywords(cardName);
    final element = _getElement(cardName);
    final archetype = _getArchetype(cardName);

    return {'keywords': keywords, 'element': element, 'archetype': archetype};
  }

  /// 获取关键词
  static List<String> _getKeywords(String cardName) {
    final card = tarot_loader.TarotData.getCardByName(cardName);
    return card == null ? const ['未知'] : List.unmodifiable(card.keywords);
  }

  /// 获取元素属性
  static String _getElement(String cardName) {
    if (cardName.startsWith('权杖')) return '火（行动、动力、创造）';
    if (cardName.startsWith('圣杯')) return '水（感受、关系、直觉）';
    if (cardName.startsWith('宝剑')) return '风（思考、沟通、决断）';
    if (cardName.startsWith('钱币')) return '土（资源、工作、现实）';
    return '大阿卡纳（核心课题与阶段转折）';
  }

  /// 获取原型
  static String _getArchetype(String cardName) {
    if (cardName.endsWith('王牌')) return '起点、种子与新机会';
    if (cardName.endsWith('侍者')) return '学习、消息与初步尝试';
    if (cardName.endsWith('骑士')) return '推进方式、行动节奏与过程';
    if (cardName.endsWith('王后')) return '内在掌握、成熟表达与照顾';
    if (cardName.endsWith('国王')) return '外在掌握、责任与决策';

    final numberMatch = RegExp(r'[二三四五六七八九十]$').firstMatch(cardName);
    if (numberMatch != null) {
      return '数字${numberMatch.group(0)}的发展阶段';
    }
    return '大阿卡纳的人生主轴';
  }
}

// ============================================
// 塔罗占卜引擎（含完整证据分析）
// ============================================

class TarotDivination {
  final RandomContext _randomContext;

  TarotDivination({dynamic seed, List<double>? replay, RandomSource? random})
    : _randomContext = createRandomContext(
        seed: seed,
        replay: replay,
        random: random,
      );

  RandomTrace _traceSince(int startIndex) {
    final trace = _randomContext.getTrace();
    return trace.copyWith(samples: trace.samples.sublist(startIndex));
  }

  /// Fisher-Yates 洗牌算法
  List<Map<String, dynamic>> _shuffleCards() {
    final allCards = tarot_loader.TarotData.cards;
    final cards = allCards.map((card) => card.toJson()).toList();

    for (int i = cards.length - 1; i > 0; i--) {
      final j = randomInt(i + 1, _randomContext.random);
      final temp = cards[i];
      cards[i] = cards[j];
      cards[j] = temp;
    }

    return cards;
  }

  /// 判断正逆位（随机）
  bool _isReversed() => _randomContext.random() < 0.5;

  /// 获取牌面证据（关键词、元素、原型）
  Map<String, dynamic> _getCardEvidence(String cardName) {
    return TarotKeywords.getCardEvidence(cardName);
  }

  /// 抽取单张牌（带完整证据分析）
  TarotDrawResult drawSingle() {
    final traceStart = _randomContext.getTrace().samples.length;
    final shuffled = _shuffleCards();
    final cardData = shuffled[0];
    final reversed = _isReversed();
    final evidence = _getCardEvidence(cardData['name']);

    final cardInput = {
      'id': cardData['number'],
      'name': cardData['name'],
      'position': '当前指引',
      'reversed': reversed,
      ...evidence,
    };

    final analysis = TarotEvidenceAnalyzer.analyzeEvidence(
      spreadType: 'single',
      spreadName: '单牌指引',
      cardInputs: [cardInput],
    );

    return TarotDrawResult(
      spreadType: 'single',
      spreadName: '单牌指引',
      cards: analysis.cards,
      evidenceAnalysis: analysis,
      timestamp: DateTime.now(),
      randomTrace: _traceSince(traceStart),
    );
  }

  /// 抽取牌阵（带完整证据分析）
  TarotDrawResult drawSpread(String spreadType) {
    final spread = tarot_loader.TarotData.spreads[spreadType];
    if (spread == null) {
      throw ArgumentError('未知的牌阵类型: $spreadType');
    }

    final traceStart = _randomContext.getTrace().samples.length;
    final shuffled = _shuffleCards();
    final cardInputs = <Map<String, dynamic>>[];

    for (int i = 0; i < spread.cardCount; i++) {
      final cardData = shuffled[i];
      final reversed = _isReversed();
      final evidence = _getCardEvidence(cardData['name']);

      cardInputs.add({
        'id': cardData['number'],
        'name': cardData['name'],
        'position': spread.positions[i],
        'reversed': reversed,
        ...evidence,
      });
    }

    final analysis = TarotEvidenceAnalyzer.analyzeEvidence(
      spreadType: spreadType,
      spreadName: spread.name,
      cardInputs: cardInputs,
    );

    return TarotDrawResult(
      spreadType: spreadType,
      spreadName: spread.name,
      cards: analysis.cards,
      evidenceAnalysis: analysis,
      timestamp: DateTime.now(),
      randomTrace: _traceSince(traceStart),
    );
  }

  /// 手动录入牌面（带完整证据分析）
  TarotDrawResult drawManual(
    String spreadType,
    List<ManualCardInput> manualCards,
  ) {
    final spread = tarot_loader.TarotData.spreads[spreadType];
    if (spread == null) {
      throw ArgumentError('未知的牌阵类型: $spreadType');
    }

    if (manualCards.length != spread.cardCount) {
      throw ArgumentError('${spread.name}需要录入${spread.cardCount}张牌');
    }

    // 检查是否有重复的牌
    final ids = manualCards.map((c) => c.id).toList();
    if (ids.toSet().length != ids.length) {
      throw ArgumentError('同一次塔罗牌阵不能重复录入同一张牌');
    }

    final cardInputs = <Map<String, dynamic>>[];

    for (int i = 0; i < manualCards.length; i++) {
      final input = manualCards[i];
      final cardData = tarot_loader.TarotData.getCardByNumber(input.id);

      if (cardData == null) {
        throw ArgumentError('第${i + 1}张塔罗牌录入无效');
      }

      final evidence = _getCardEvidence(cardData.name);

      cardInputs.add({
        'id': cardData.number,
        'name': cardData.name,
        'position': spread.positions[i],
        'reversed': input.reversed,
        ...evidence,
      });
    }

    final analysis = TarotEvidenceAnalyzer.analyzeEvidence(
      spreadType: spreadType,
      spreadName: spread.name,
      cardInputs: cardInputs,
    );

    return TarotDrawResult(
      spreadType: spreadType,
      spreadName: spread.name,
      cards: analysis.cards,
      evidenceAnalysis: analysis,
      timestamp: DateTime.now(),
    );
  }
}
