// ignore_for_file: avoid_print

/// 塔罗占卜使用示例
library;

import 'package:zhaoxingzhai/core/data/tarot_data.dart';
import 'package:zhaoxingzhai/core/engine/tarot/tarot_divination.dart';

void main() async {
  print('🔮 塔罗占卜示例\n');

  // 加载塔罗牌数据
  await TarotData.load();
  print('✅ 塔罗牌数据加载完成\n');

  // 创建占卜引擎
  final tarot = TarotDivination();

  // ==========================================
  // 示例 1: 单牌指引
  // ==========================================
  print('📖 示例 1: 单牌指引');
  print('─' * 50);

  final singleResult = tarot.drawSingle();
  print('牌阵: ${singleResult.spreadName}');
  print('抽牌时间: ${singleResult.timestamp}');
  print('');

  final singleCard = singleResult.cards[0];
  print('${singleCard.position}: ${singleCard.name} ${singleCard.orientation}');
  print('关键词: ${singleCard.keywords.join('、')}');
  print('元素: ${singleCard.element}');
  print('原型: ${singleCard.archetype}');
  print('');

  print('📊 证据分析:');
  print(singleResult.evidenceAnalysis.promptText);
  print('');

  // ==========================================
  // 示例 2: 时间流牌阵（三张牌）
  // ==========================================
  print('📖 示例 2: 时间流牌阵');
  print('─' * 50);

  final threeResult = tarot.drawSpread('three');
  print('牌阵: ${threeResult.spreadName}');
  print('抽牌时间: ${threeResult.timestamp}');
  print('');

  for (final card in threeResult.cards) {
    print('${card.position}: ${card.name} ${card.orientation}');
    print('  关键词: ${card.keywords.join('、')}');
    print('  元素: ${card.element}');
    print('');
  }

  print('📊 证据分析:');
  print(threeResult.evidenceAnalysis.promptText);
  print('');

  // ==========================================
  // 示例 3: 凯尔特十字牌阵
  // ==========================================
  print('📖 示例 3: 凯尔特十字牌阵（完整解读）');
  print('─' * 50);

  final crossResult = tarot.drawSpread('celtic');
  print('牌阵: ${crossResult.spreadName}');
  print('抽牌时间: ${crossResult.timestamp}');
  print('');

  for (int i = 0; i < crossResult.cards.length; i++) {
    final card = crossResult.cards[i];
    print('${i + 1}. ${card.position}: ${card.name} ${card.orientation}');
    print('   关键词: ${card.keywords.join('、')}');
  }
  print('');

  print('📊 证据分析（节选）:');
  final lines = crossResult.evidenceAnalysis.promptText.split('\n');
  for (final line in lines.take(20)) {
    print(line);
  }
  if (lines.length > 20) {
    print('... (共${lines.length}行)');
  }
  print('');

  // ==========================================
  // 示例 4: 手动录入牌面
  // ==========================================
  print('📖 示例 4: 手动录入牌面（时间流牌阵）');
  print('─' * 50);

  final manualCards = [
    ManualCardInput(id: 1, reversed: false), // 愚者 正位
    ManualCardInput(id: 10, reversed: true), // 命运之轮 逆位
    ManualCardInput(id: 21, reversed: false), // 世界 正位
  ];

  final manualResult = tarot.drawManual('three', manualCards);
  print('牌阵: ${manualResult.spreadName}');
  print('');

  for (final card in manualResult.cards) {
    print('${card.position}: ${card.name} ${card.orientation}');
    print('  关键词: ${card.keywords.join('、')}');
    if (card.constraints.isNotEmpty) {
      print('  ⚠️  约束: ${card.constraints.join('；')}');
    }
    print('');
  }

  // 显示元素互参分析
  final elementFacts = manualResult.evidenceAnalysis.elementInteractionFacts;
  if (elementFacts.isNotEmpty) {
    print('🔗 元素互参关系:');
    for (final fact in elementFacts) {
      print('  ${fact.promptText}');
    }
    print('');
  }

  // 显示逆位反证
  final counterFacts = manualResult.evidenceAnalysis.counterEvidenceFacts;
  if (counterFacts.isNotEmpty) {
    print('⚠️  逆位反证（${counterFacts.length}条）:');
    for (final fact in counterFacts) {
      print('  ${fact.promptText}');
    }
    print('');
  }

  print('📊 证据汇总:');
  print(manualResult.evidenceAnalysis.summaryFact.promptText);
  print('');

  // ==========================================
  // 方法论说明
  // ==========================================
  print('📚 方法论:');
  print('─' * 50);
  for (final method in manualResult.evidenceAnalysis.methodology) {
    print('• $method');
  }
  print('');

  print('✅ 塔罗占卜示例完成！');
  print('');
  print('💡 说明:');
  print('  - 包含完整的证据分析系统');
  print('  - 支持正逆位判断');
  print('  - 支持元素互参关系');
  print('  - 支持逆位反证约束');
  print('  - 符合项目的严格推理标准');
}
