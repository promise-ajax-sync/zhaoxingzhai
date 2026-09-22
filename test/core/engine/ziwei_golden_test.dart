import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/engine/ziwei/ziwei_chart.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('甲辰年正月初一子时火六局标准盘', () async {
    final result = await ZiweiChartEngine.calculate(
      CaseSnapshot(
        caseId: 'ziwei-golden-2024-01-01-zi',
        name: '标准盘',
        gender: CaseGender.male,
        calendarType: CaseCalendarType.lunar,
        birthDateTime: DateTime(2024, 1, 1),
      ),
    );
    final byStar = <String, String>{
      for (final palace in result.palaces)
        for (final star in palace.stars) star.name: palace.position.branch,
    };

    expect(result.yearStem, '甲');
    expect(result.yearBranch, '辰');
    expect(result.foundation.lifeBranch, '寅');
    expect(result.foundation.bodyBranch, '寅');
    expect(result.foundation.fiveElementBureau, '火六局');
    expect(byStar, {
      '紫微': '酉',
      '天机': '申',
      '太阳': '午',
      '武曲': '巳',
      '天同': '辰',
      '廉贞': '丑',
      '天府': '未',
      '太阴': '申',
      '贪狼': '酉',
      '巨门': '戌',
      '天相': '亥',
      '天梁': '子',
      '七杀': '丑',
      '破军': '巳',
      '左辅': '辰',
      '右弼': '戌',
      '文昌': '戌',
      '文曲': '辰',
      '天魁': '丑',
      '天钺': '未',
      '禄存': '寅',
      '擎羊': '卯',
      '陀罗': '丑',
      '天马': '寅',
      '火星': '寅',
      '铃星': '戌',
      '地劫': '亥',
      '地空': '亥',
    });
    expect(result.limits.direction.name, 'forward');
    expect(result.limits.startNominalAge, 6);
    expect(result.limits.decades.first.palace.name, '命宫');
  });
}
