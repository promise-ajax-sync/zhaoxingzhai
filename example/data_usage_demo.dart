// ignore_for_file: avoid_print

/// 数据加载和使用演示
///
/// 这个示例展示如何在 Flutter 应用中使用导出的数据
library;

import 'package:zhaoxingzhai/core/data/tarot_data.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/data/ganzhi_data.dart';

void main() async {
  print('🎯 兆星斋数据加载演示\n');

  // ========================================
  // 1. 预加载所有数据
  // ========================================
  print('📦 正在加载数据...');
  await Future.wait([TarotData.load(), HexagramData.load(), GanzhiData.load()]);
  print('✅ 数据加载完成！\n');

  // ========================================
  // 2. 塔罗牌数据演示
  // ========================================
  print('🃏 === 塔罗牌数据 ===');

  // 获取所有牌
  final allCards = TarotData.cards;
  print('总计: ${allCards.length} 张牌');

  // 获取大阿卡纳
  final majorArcana = TarotData.majorArcana;
  print('大阿卡纳: ${majorArcana.length} 张');
  print('  示例: ${majorArcana.take(3).map((c) => c.name).join('、')}');

  // 获取小阿卡纳
  final minorArcana = TarotData.minorArcana;
  print('小阿卡纳: ${minorArcana.length} 张');

  // 按花色获取
  final wands = TarotData.getCardsBySuit('权杖');
  final cups = TarotData.getCardsBySuit('圣杯');
  final swords = TarotData.getCardsBySuit('宝剑');
  final coins = TarotData.getCardsBySuit('钱币');
  print('  权杖: ${wands.length} 张');
  print('  圣杯: ${cups.length} 张');
  print('  宝剑: ${swords.length} 张');
  print('  钱币: ${coins.length} 张');

  // 根据编号获取牌
  final fool = TarotData.getCardByNumber(1);
  print('编号1: ${fool?.name} (${fool?.type})');

  // 获取牌阵
  final spreads = TarotData.spreads;
  print('牌阵数量: ${spreads.length}');
  spreads.forEach((key, spread) {
    print('  ${spread.name}: ${spread.cardCount}张牌');
  });
  print('');

  // ========================================
  // 3. 八卦数据演示
  // ========================================
  print('☯️  === 八卦数据 ===');

  final trigrams = HexagramData.trigrams;
  print('总计: ${trigrams.length} 个八卦');

  for (final trigram in trigrams) {
    print(
      '  ${trigram.symbol} ${trigram.name} - ${trigram.nature} - ${trigram.element}',
    );
  }

  // 根据名称获取八卦
  final qian = HexagramData.getTrigramByName('乾');
  print('\n乾卦详情:');
  print('  符号: ${qian?.symbol}');
  print('  自然: ${qian?.nature}');
  print('  五行: ${qian?.element}');
  print('  爻线: ${qian?.lines}');
  print('  二进制: ${qian?.binary}');
  print('');

  // ========================================
  // 4. 六十四卦数据演示
  // ========================================
  print('🔮 === 六十四卦数据 ===');

  final hexagrams = HexagramData.hexagrams;
  print('总计: ${hexagrams.length} 个六十四卦');

  // 根据ID获取卦
  final qianWeiTian = HexagramData.getHexagramById(1);
  print('\n第1卦详情:');
  print('  名称: ${qianWeiTian?.name}');
  print('  符号: ${qianWeiTian?.symbol}');
  print('  上卦: ${qianWeiTian?.upper}');
  print('  下卦: ${qianWeiTian?.lower}');
  print('  宫位: ${qianWeiTian?.palace}');
  print('  卦辞: ${qianWeiTian?.description}');

  // 按宫位获取
  final qianGong = HexagramData.getHexagramsByPalace('乾');
  print('\n乾宫共有 ${qianGong.length} 个卦:');
  for (final hex in qianGong) {
    print('  ${hex.id}. ${hex.name} ${hex.symbol}');
  }

  // 统计各宫卦数
  final palaces = ['乾', '坎', '艮', '震', '巽', '离', '坤', '兑'];
  print('\n八宫卦象分布:');
  for (final palace in palaces) {
    final count = HexagramData.getHexagramsByPalace(palace).length;
    print('  $palace宫: $count 卦');
  }
  print('');

  // ========================================
  // 5. 干支数据演示
  // ========================================
  print('🀄 === 干支数据 ===');

  final tiangan = GanzhiData.tiangan;
  final dizhi = GanzhiData.dizhi;
  print('天干: ${tiangan.join(' ')} (${tiangan.length}个)');
  print('地支: ${dizhi.join(' ')} (${dizhi.length}个)');

  // 生成六十甲子
  final sixtyJiazi = GanzhiData.sixtyJiazi;
  print('\n六十甲子 (${sixtyJiazi.length}个):');

  // 分10行显示
  for (int i = 0; i < 60; i += 10) {
    final row = sixtyJiazi.skip(i).take(10).join(' ');
    print('  $row');
  }

  // 根据索引获取
  print('\n索引示例:');
  print('  索引0: ${GanzhiData.getTiangan(0)}${GanzhiData.getDizhi(0)}');
  print('  索引10: ${GanzhiData.getTiangan(10)}${GanzhiData.getDizhi(10)}');
  print(
    '  索引60: ${GanzhiData.getTiangan(60)}${GanzhiData.getDizhi(60)} (自动循环)',
  );
  print('');

  // ========================================
  // 6. 综合应用示例
  // ========================================
  print('🎲 === 综合应用示例 ===');

  // 示例: 随机抽一张塔罗牌
  final randomIndex = DateTime.now().millisecond % allCards.length;
  final randomCard = allCards[randomIndex];
  print('随机抽牌: ${randomCard.name} (${randomCard.type})');

  // 示例: 今日卦象（使用日期作为种子）
  final now = DateTime.now();
  final hexIndex = (now.day + now.month * 100) % hexagrams.length;
  final todayHex = hexagrams[hexIndex];
  print('今日卦象: ${todayHex.name} - ${todayHex.description}');

  // 示例: 今日干支
  final ganIndex = now.day % 10;
  final zhiIndex = now.day % 12;
  final todayGanzhi =
      '${GanzhiData.getTiangan(ganIndex)}${GanzhiData.getDizhi(zhiIndex)}';
  print('今日干支: $todayGanzhi');

  print('\n✅ 演示完成！');
  print('💡 数据已就绪，可以开始开发术式算法了！');
}
