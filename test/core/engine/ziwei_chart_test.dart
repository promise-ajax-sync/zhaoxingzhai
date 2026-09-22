import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/ziwei_data.dart';
import 'package:zhaoxingzhai/core/engine/ziwei/ziwei_chart.dart';
import 'package:zhaoxingzhai/core/engine/ziwei/ziwei_foundation.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CaseSnapshot subject({
    String id = 'chart',
    CaseCalendarType calendarType = CaseCalendarType.solar,
    required DateTime birth,
  }) => CaseSnapshot(
    caseId: id,
    name: '测试角色',
    gender: CaseGender.male,
    calendarType: calendarType,
    birthDateTime: birth,
  );

  List<ZiweiPlacedStar> starsOf(ZiweiChartResult result) =>
      result.palaces.expand((e) => e.stars).toList(growable: false);

  int starIndex(ZiweiChartResult result, String name) => result.palaces
      .singleWhere((palace) => palace.stars.any((star) => star.name == name))
      .position
      .index;

  int branchIndex(String branch) =>
      ZiweiFoundationEngine.branches.indexOf(branch);

  int timeBranchIndex(String branch) => const [
    '子',
    '丑',
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '亥',
  ].indexOf(branch);

  int mod(int value) => (value % 12 + 12) % 12;

  test('二十八颗基础星曜全部安置且与自有数据表一致', () async {
    final result = await ZiweiChartEngine.calculate(
      subject(id: 'chart-1', birth: DateTime(1990, 5, 17, 12)),
    );
    final stars = starsOf(result);
    final definitions = await ZiweiData.loadStars();
    expect(stars, hasLength(28));
    expect(stars.map((e) => e.name).toSet(), hasLength(28));
    expect(
      stars.map((e) => e.name).toSet(),
      definitions.map((e) => e.name).toSet(),
    );
    expect(stars.any((e) => e.name == '紫微'), isTrue);
    expect(stars.any((e) => e.name == '天府'), isTrue);
    expect(result.brightnessProfileId, 'quanshu-seven-tier-v1');
    expect(stars.where((e) => e.brightness != null), hasLength(20));
    expect(
      stars
          .where((e) => e.brightness != null)
          .every(
            (e) => {'庙', '旺', '得', '利', '平', '不', '陷'}.contains(e.brightness),
          ),
      isTrue,
    );
    expect(result.palaces, hasLength(12));
    expect(
      result.toJson()['algorithmVersion'],
      ZiweiChartResult.algorithmVersion,
    );
  });

  test('月系与时系辅星按固定起宫顺逆布置', () async {
    final result = await ZiweiChartEngine.calculate(
      subject(
        id: 'chart-rules',
        calendarType: CaseCalendarType.lunar,
        birth: DateTime(2024, 4, 12, 8),
      ),
    );
    final monthOffset = result.foundation.lunarMonth.abs() - 1;
    final timeIndex = timeBranchIndex(result.foundation.timeBranch);
    expect(starIndex(result, '左辅'), mod(branchIndex('辰') + monthOffset));
    expect(starIndex(result, '右弼'), mod(branchIndex('戌') - monthOffset));
    expect(starIndex(result, '文昌'), mod(branchIndex('戌') - timeIndex));
    expect(starIndex(result, '文曲'), mod(branchIndex('辰') + timeIndex));
    expect(starIndex(result, '地劫'), mod(branchIndex('亥') + timeIndex));
    expect(starIndex(result, '地空'), mod(branchIndex('亥') - timeIndex));
  });

  test('禄存、擎羊、陀罗始终保持前后相邻', () async {
    final result = await ZiweiChartEngine.calculate(
      subject(id: 'chart-lucun', birth: DateTime(1990, 5, 17, 12)),
    );
    final lucun = starIndex(result, '禄存');
    expect(starIndex(result, '擎羊'), mod(lucun + 1));
    expect(starIndex(result, '陀罗'), mod(lucun - 1));
  });

  test('天马按生年地支三合组定位', () async {
    final cases = <DateTime, String>{
      DateTime(2022, 6, 1, 12): '申',
      DateTime(2020, 6, 1, 12): '寅',
      DateTime(2025, 6, 1, 12): '亥',
      DateTime(2023, 6, 1, 12): '巳',
    };
    for (final entry in cases.entries) {
      final result = await ZiweiChartEngine.calculate(
        subject(id: 'chart-horse-${entry.key.year}', birth: entry.key),
      );
      expect(
        starIndex(result, '天马'),
        branchIndex(entry.value),
        reason: '${result.yearBranch}年的天马宫位',
      );
    }
  });

  test('火铃采用四三合起宫、火顺铃逆的 v1 口径', () async {
    final result = await ZiweiChartEngine.calculate(
      subject(
        id: 'chart-fire-bell',
        calendarType: CaseCalendarType.lunar,
        birth: DateTime(2022, 5, 1, 8),
      ),
    );
    final timeIndex = timeBranchIndex(result.foundation.timeBranch);
    expect(result.yearBranch, '寅');
    expect(starIndex(result, '火星'), mod(branchIndex('丑') + timeIndex));
    expect(starIndex(result, '铃星'), mod(branchIndex('卯') - timeIndex));
  });

  test('生年四化在主星与辅星安齐后恰好标记四颗', () async {
    final result = await ZiweiChartEngine.calculate(
      subject(
        id: 'chart-2',
        calendarType: CaseCalendarType.lunar,
        birth: DateTime(2024, 1, 1, 8),
      ),
    );
    final transformed = starsOf(result)
        .where((e) => e.mutagen != null)
        .toList();
    expect(transformed, hasLength(4));
    expect(transformed.map((e) => e.mutagen).toSet(), {'禄', '权', '科', '忌'});
  });

  test('每个宫位生成两个三合宫和一个对宫', () async {
    final result = await ZiweiChartEngine.calculate(
      subject(id: 'chart-relations', birth: DateTime(1990, 5, 17, 12)),
    );
    expect(result.relations, hasLength(12));
    for (final relation in result.relations) {
      expect(relation.trines, hasLength(2));
      expect({
        relation.source.index,
        ...relation.trines.map((e) => e.index),
        relation.opposite.index,
      }, hasLength(4));
      expect(mod(relation.opposite.index - relation.source.index), 6);
      expect(
        relation.trines
            .map((e) => mod(e.index - relation.source.index))
            .toSet(),
        {4, 8},
      );
    }
  });

  test('每个大限按限宫天干生成四化落宫', () async {
    final result = await ZiweiChartEngine.calculate(
      subject(
        id: 'chart-decade-mutagens',
        calendarType: CaseCalendarType.lunar,
        birth: DateTime(2024, 1, 1),
      ),
    );
    expect(result.decadeTransformations, hasLength(12));
    for (final transformation in result.decadeTransformations) {
      expect(transformation.stem, transformation.limit.palace.stem);
      expect(transformation.placements, hasLength(4));
      expect(transformation.placements.map((e) => e.mutagen).toSet(), {
        '禄',
        '权',
        '科',
        '忌',
      });
      expect(
        transformation.placements.every(
          (e) => result.palaces.any((p) => p.position == e.destination),
        ),
        isTrue,
      );
    }
  });

  test('同一出生资料重复计算得到相同主星盘', () async {
    final stableSubject = subject(
      id: 'chart-3',
      birth: DateTime(2000, 1, 1, 23, 30),
    );
    final first = await ZiweiChartEngine.calculate(stableSubject);
    ZiweiData.resetForTest();
    final second = await ZiweiChartEngine.calculate(stableSubject);
    expect(first.toJson(), second.toJson());
  });
}
