import 'package:zhaoxingzhai/core/engine/ziwei/ziwei_foundation.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';

enum ZiweiLimitDirection {
  forward('顺行'),
  reverse('逆行'),
  undetermined('待确定');

  const ZiweiLimitDirection(this.label);
  final String label;
}

class ZiweiDecadeLimit {
  const ZiweiDecadeLimit({
    required this.order,
    required this.startNominalAge,
    required this.endNominalAge,
    required this.palace,
  });

  final int order;
  final int startNominalAge;
  final int endNominalAge;
  final ZiweiPalacePosition palace;

  Map<String, dynamic> toJson() => {
    'order': order,
    'startNominalAge': startNominalAge,
    'endNominalAge': endNominalAge,
    'palace': palace.toJson(),
  };
}

class ZiweiLimitResult {
  const ZiweiLimitResult({
    required this.direction,
    required this.startNominalAge,
    required this.decades,
  });

  static const algorithmVersion = 'ziwei-decadal-limits-v1';
  final ZiweiLimitDirection direction;
  final int startNominalAge;
  final List<ZiweiDecadeLimit> decades;

  Map<String, dynamic> toJson() => {
    'algorithmVersion': algorithmVersion,
    'direction': direction.name,
    'directionLabel': direction.label,
    'ageConvention': 'nominal-age',
    'startNominalAge': startNominalAge,
    'decades': decades.map((e) => e.toJson()).toList(growable: false),
  };
}

abstract final class ZiweiLimitEngine {
  static const _yangStems = {'甲', '丙', '戊', '庚', '壬'};

  static ZiweiLimitResult calculate({
    required ZiweiFoundationResult foundation,
    required String yearStem,
  }) {
    final gender = foundation.subject.gender;
    if (gender == CaseGender.unspecified) {
      return const ZiweiLimitResult(
        direction: ZiweiLimitDirection.undetermined,
        startNominalAge: 0,
        decades: [],
      );
    }
    final isYangYear = _yangStems.contains(yearStem);
    final isForward =
        (isYangYear && gender == CaseGender.male) ||
        (!isYangYear && gender == CaseGender.female);
    final direction = isForward
        ? ZiweiLimitDirection.forward
        : ZiweiLimitDirection.reverse;
    final step = isForward ? 1 : -1;
    final lifeIndex = foundation.palaces.singleWhere((e) => e.isLife).index;
    final startAge = foundation.bureauNumber;
    final decades = List.generate(12, (order) {
      final palaceIndex = _mod(lifeIndex + step * order, 12);
      final palace = foundation.palaces.singleWhere(
        (e) => e.index == palaceIndex,
      );
      final decadeStart = startAge + order * 10;
      return ZiweiDecadeLimit(
        order: order + 1,
        startNominalAge: decadeStart,
        endNominalAge: decadeStart + 9,
        palace: palace,
      );
    }, growable: false);
    return ZiweiLimitResult(
      direction: direction,
      startNominalAge: startAge,
      decades: decades,
    );
  }

  static int _mod(int value, int divisor) =>
      (value % divisor + divisor) % divisor;
}
