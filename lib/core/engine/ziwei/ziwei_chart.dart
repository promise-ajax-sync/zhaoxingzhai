import 'package:lunar/lunar.dart';
import 'package:zhaoxingzhai/core/data/ziwei_data.dart';
import 'package:zhaoxingzhai/core/engine/ziwei/ziwei_foundation.dart';
import 'package:zhaoxingzhai/core/engine/ziwei/ziwei_limits.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';

class ZiweiPlacedStar {
  const ZiweiPlacedStar({
    required this.name,
    required this.group,
    this.mutagen,
    this.brightness,
  });
  final String name;
  final String group;
  final String? mutagen;
  final String? brightness;
  Map<String, dynamic> toJson() => {
    'name': name,
    'group': group,
    if (mutagen != null) 'mutagen': mutagen,
    if (brightness != null) 'brightness': brightness,
  };
}

class ZiweiChartPalace {
  const ZiweiChartPalace({required this.position, required this.stars});
  final ZiweiPalacePosition position;
  final List<ZiweiPlacedStar> stars;
  Map<String, dynamic> toJson() => {
    ...position.toJson(),
    'stars': stars.map((e) => e.toJson()).toList(),
  };
}

class ZiweiPalaceRelations {
  const ZiweiPalaceRelations({
    required this.source,
    required this.trines,
    required this.opposite,
  });

  final ZiweiPalacePosition source;
  final List<ZiweiPalacePosition> trines;
  final ZiweiPalacePosition opposite;

  Map<String, dynamic> toJson() => {
    'source': source.toJson(),
    'trines': trines.map((e) => e.toJson()).toList(growable: false),
    'opposite': opposite.toJson(),
  };
}

class ZiweiMutagenPlacement {
  const ZiweiMutagenPlacement({
    required this.starName,
    required this.mutagen,
    required this.destination,
  });

  final String starName;
  final String mutagen;
  final ZiweiPalacePosition destination;

  Map<String, dynamic> toJson() => {
    'starName': starName,
    'mutagen': mutagen,
    'destination': destination.toJson(),
  };
}

class ZiweiDecadeTransformations {
  const ZiweiDecadeTransformations({
    required this.limit,
    required this.stem,
    required this.placements,
  });

  final ZiweiDecadeLimit limit;
  final String stem;
  final List<ZiweiMutagenPlacement> placements;

  Map<String, dynamic> toJson() => {
    'limitOrder': limit.order,
    'startNominalAge': limit.startNominalAge,
    'endNominalAge': limit.endNominalAge,
    'palace': limit.palace.toJson(),
    'stem': stem,
    'placements': placements.map((e) => e.toJson()).toList(growable: false),
  };
}

class ZiweiChartResult {
  const ZiweiChartResult({
    required this.foundation,
    required this.yearStem,
    required this.yearBranch,
    required this.brightnessProfileId,
    required this.limits,
    required this.palaces,
    required this.relations,
    required this.decadeTransformations,
  });
  static const algorithmVersion =
      'ziwei-foundation-stars-brightness-relations-v3';
  final ZiweiFoundationResult foundation;
  final String yearStem;
  final String yearBranch;
  final String brightnessProfileId;
  final ZiweiLimitResult limits;
  final List<ZiweiChartPalace> palaces;
  final List<ZiweiPalaceRelations> relations;
  final List<ZiweiDecadeTransformations> decadeTransformations;
  ZiweiChartPalace get lifePalace =>
      palaces.singleWhere((e) => e.position.isLife);
  Map<String, dynamic> toJson() => {
    'algorithmVersion': algorithmVersion,
    'foundation': foundation.toJson(),
    'yearStem': yearStem,
    'yearBranch': yearBranch,
    'brightnessProfileId': brightnessProfileId,
    'limits': limits.toJson(),
    'palaces': palaces.map((e) => e.toJson()).toList(),
    'relations': relations.map((e) => e.toJson()).toList(growable: false),
    'decadeTransformations': decadeTransformations
        .map((e) => e.toJson())
        .toList(growable: false),
  };
}

abstract final class ZiweiChartEngine {
  static const _ziweiOffsets = <String, int>{
    '紫微': 0,
    '天机': -1,
    '太阳': -3,
    '武曲': -4,
    '天同': -5,
    '廉贞': -8,
  };
  static const _tianfuOffsets = <String, int>{
    '天府': 0,
    '太阴': 1,
    '贪狼': 2,
    '巨门': 3,
    '天相': 4,
    '天梁': 5,
    '七杀': 6,
    '破军': 10,
  };
  static const _mutagenLabels = ['禄', '权', '科', '忌'];

  static Future<ZiweiChartResult> calculate(CaseSnapshot subject) async {
    final foundation = ZiweiFoundationEngine.calculate(subject);
    final mutagens = await ZiweiData.loadMutagens();
    final brightness = await ZiweiData.loadBrightness();
    final lunar = _lunar(subject);
    final yearStem = lunar.getYearGan();
    final yearBranch = lunar.getYearZhi();
    final starsByIndex = {for (var i = 0; i < 12; i++) i: <ZiweiPlacedStar>[]};
    final ziweiIndex = _ziweiIndex(
      foundation.lunarDay,
      foundation.bureauNumber,
    );
    final tianfuIndex = _mod(-ziweiIndex, 12);
    void place(Map<String, int> offsets, int origin) {
      for (final entry in offsets.entries) {
        final index = _mod(origin + entry.value, 12);
        starsByIndex[index]!.add(
          ZiweiPlacedStar(
            name: entry.key,
            group: 'major',
            mutagen: _mutagen(entry.key, mutagens[yearStem]),
            brightness: brightness.lookup(
              entry.key,
              ZiweiFoundationEngine.branches[index],
            ),
          ),
        );
      }
    }

    place(_ziweiOffsets, ziweiIndex);
    place(_tianfuOffsets, tianfuIndex);
    void add(String name, String group, int index) {
      final normalizedIndex = _mod(index, 12);
      starsByIndex[normalizedIndex]!.add(
        ZiweiPlacedStar(
          name: name,
          group: group,
          mutagen: _mutagen(name, mutagens[yearStem]),
          brightness: brightness.lookup(
            name,
            ZiweiFoundationEngine.branches[normalizedIndex],
          ),
        ),
      );
    }

    final monthOffset = foundation.lunarMonth.abs() - 1;
    final timeIndex = LunarUtil.ZHI.indexOf(foundation.timeBranch) - 1;
    add('左辅', 'assistant', _branchIndex('辰') + monthOffset);
    add('右弼', 'assistant', _branchIndex('戌') - monthOffset);
    add('文昌', 'literary', _branchIndex('戌') - timeIndex);
    add('文曲', 'literary', _branchIndex('辰') + timeIndex);
    final noble = _nobleBranches(yearStem);
    add('天魁', 'noble', _branchIndex(noble.$1));
    add('天钺', 'noble', _branchIndex(noble.$2));
    final lucunIndex = _branchIndex(_lucunBranch(yearStem));
    add('禄存', 'fortune', lucunIndex);
    add('擎羊', 'malefic', lucunIndex + 1);
    add('陀罗', 'malefic', lucunIndex - 1);
    add('天马', 'movement', _branchIndex(_tianmaBranch(yearBranch)));
    final fireBell = _fireBellStart(yearBranch);
    add('火星', 'malefic', _branchIndex(fireBell.$1) + timeIndex);
    add('铃星', 'malefic', _branchIndex(fireBell.$2) - timeIndex);
    add('地劫', 'void', _branchIndex('亥') + timeIndex);
    add('地空', 'void', _branchIndex('亥') - timeIndex);
    final palaces = foundation.palaces
        .map(
          (position) => ZiweiChartPalace(
            position: position,
            stars: List.unmodifiable(starsByIndex[position.index]!),
          ),
        )
        .toList(growable: false);
    final limits = ZiweiLimitEngine.calculate(
      foundation: foundation,
      yearStem: yearStem,
    );
    final palaceByIndex = {
      for (final palace in palaces) palace.position.index: palace,
    };
    final relations = palaces
        .map((palace) {
          final index = palace.position.index;
          return ZiweiPalaceRelations(
            source: palace.position,
            trines: [
              palaceByIndex[_mod(index + 4, 12)]!.position,
              palaceByIndex[_mod(index + 8, 12)]!.position,
            ],
            opposite: palaceByIndex[_mod(index + 6, 12)]!.position,
          );
        })
        .toList(growable: false);
    final decadeTransformations = limits.decades
        .map((limit) {
          final sequence = mutagens[limit.palace.stem] ?? const <String>[];
          final placements = <ZiweiMutagenPlacement>[];
          for (var i = 0; i < sequence.length; i++) {
            final starName = sequence[i];
            final destination = palaces.singleWhere(
              (palace) => palace.stars.any((star) => star.name == starName),
            );
            placements.add(
              ZiweiMutagenPlacement(
                starName: starName,
                mutagen: _mutagenLabels[i],
                destination: destination.position,
              ),
            );
          }
          return ZiweiDecadeTransformations(
            limit: limit,
            stem: limit.palace.stem,
            placements: List.unmodifiable(placements),
          );
        })
        .toList(growable: false);
    return ZiweiChartResult(
      foundation: foundation,
      yearStem: yearStem,
      yearBranch: yearBranch,
      brightnessProfileId: brightness.profileId,
      limits: limits,
      palaces: palaces,
      relations: relations,
      decadeTransformations: decadeTransformations,
    );
  }

  static int _ziweiIndex(int lunarDay, int bureauNumber) {
    final quotient = (lunarDay / bureauNumber).ceil();
    final difference = quotient * bureauNumber - lunarDay;
    final count = difference.isEven
        ? quotient + difference
        : quotient - difference;
    return _mod(count - 1, 12);
  }

  static String? _mutagen(String star, List<String>? sequence) {
    if (sequence == null) return null;
    final index = sequence.indexOf(star);
    return index < 0 ? null : _mutagenLabels[index];
  }

  static int _branchIndex(String branch) {
    final index = ZiweiFoundationEngine.branches.indexOf(branch);
    if (index < 0) throw ArgumentError('无法识别地支：$branch');
    return index;
  }

  static (String, String) _nobleBranches(String stem) => switch (stem) {
    '甲' || '戊' || '庚' => ('丑', '未'),
    '乙' || '己' => ('子', '申'),
    '丙' || '丁' => ('亥', '酉'),
    '辛' => ('午', '寅'),
    '壬' || '癸' => ('卯', '巳'),
    _ => throw ArgumentError('无法识别天干：$stem'),
  };

  static String _lucunBranch(String stem) => switch (stem) {
    '甲' => '寅',
    '乙' => '卯',
    '丙' || '戊' => '巳',
    '丁' || '己' => '午',
    '庚' => '申',
    '辛' => '酉',
    '壬' => '亥',
    '癸' => '子',
    _ => throw ArgumentError('无法识别天干：$stem'),
  };

  static String _tianmaBranch(String branch) => switch (branch) {
    '寅' || '午' || '戌' => '申',
    '申' || '子' || '辰' => '寅',
    '巳' || '酉' || '丑' => '亥',
    '亥' || '卯' || '未' => '巳',
    _ => throw ArgumentError('无法识别地支：$branch'),
  };

  static (String, String) _fireBellStart(String branch) => switch (branch) {
    '寅' || '午' || '戌' => ('丑', '卯'),
    '申' || '子' || '辰' => ('寅', '戌'),
    '巳' || '酉' || '丑' => ('卯', '戌'),
    '亥' || '卯' || '未' => ('酉', '戌'),
    _ => throw ArgumentError('无法识别地支：$branch'),
  };

  static Lunar _lunar(CaseSnapshot subject) {
    final value = subject.birthDateTime;
    return subject.calendarType == CaseCalendarType.lunar
        ? Lunar.fromYmdHms(
            value.year,
            subject.isLeapMonth ? -value.month : value.month,
            value.day,
            value.hour,
            value.minute,
            value.second,
          )
        : Solar.fromYmdHms(
            value.year,
            value.month,
            value.day,
            value.hour,
            value.minute,
            value.second,
          ).getLunar();
  }

  static int _mod(int value, int divisor) =>
      (value % divisor + divisor) % divisor;
}
