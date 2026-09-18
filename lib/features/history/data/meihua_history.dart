import 'package:zhaoxingzhai/features/history/data/daily_hexagram_history.dart';
import 'package:zhaoxingzhai/features/history/data/divination_history_repository.dart';
import 'package:zhaoxingzhai/core/interpretation/meihua_interpretation.dart';
import 'package:zhaoxingzhai/core/models/meihua_consultation_context.dart';

class HistoricalMeihuaRole {
  const HistoricalMeihuaRole({required this.name, required this.element});

  final String name;
  final String element;

  static HistoricalMeihuaRole? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final name = map['name'];
    final element = map['element'];
    if (name is! String || name.isEmpty || element is! String) return null;
    return HistoricalMeihuaRole(name: name, element: element);
  }
}

class MeihuaHistoryDetails {
  const MeihuaHistoryDetails({
    required this.methodLabel,
    required this.original,
    required this.inter,
    required this.changed,
    required this.movingLine,
    required this.tiGua,
    required this.yongGua,
    required this.relation,
    required this.calculation,
    required this.randomSamples,
    required this.interpretation,
    required this.consultationContext,
  });

  final String methodLabel;
  final HistoricalHexagramSnapshot original;
  final HistoricalHexagramSnapshot inter;
  final HistoricalHexagramSnapshot changed;
  final HistoricalMovingLine movingLine;
  final HistoricalMeihuaRole tiGua;
  final HistoricalMeihuaRole yongGua;
  final String relation;
  final Map<String, dynamic> calculation;
  final List<double> randomSamples;
  final MeihuaInterpretation? interpretation;
  final MeihuaConsultationContext? consultationContext;

  static MeihuaHistoryDetails? tryParse(DivinationHistoryRecord record) {
    if (record.type != 'meihua') return null;
    final payload = record.payload;
    final original = HistoricalHexagramSnapshot.tryParse(payload['original']);
    final inter = HistoricalHexagramSnapshot.tryParse(payload['inter']);
    final changed = HistoricalHexagramSnapshot.tryParse(payload['changed']);
    final moving = HistoricalMovingLine.tryParse(payload['movingYao']);
    final ti = HistoricalMeihuaRole.tryParse(payload['tiGua']);
    final yong = HistoricalMeihuaRole.tryParse(payload['yongGua']);
    final relation = payload['tiYongRelation'];
    if (original == null ||
        inter == null ||
        changed == null ||
        moving == null ||
        ti == null ||
        yong == null ||
        relation is! String) {
      return null;
    }
    final trace = payload['randomTrace'] is Map
        ? Map<String, dynamic>.from(payload['randomTrace'] as Map)
        : const <String, dynamic>{};
    return MeihuaHistoryDetails(
      methodLabel: payload['methodLabel'] is String
          ? payload['methodLabel'] as String
          : '梅花易数',
      original: original,
      inter: inter,
      changed: changed,
      movingLine: moving,
      tiGua: ti,
      yongGua: yong,
      relation: relation,
      calculation: payload['calculation'] is Map
          ? Map<String, dynamic>.from(payload['calculation'] as Map)
          : const <String, dynamic>{},
      randomSamples: trace['samples'] is List
          ? (trace['samples'] as List)
                .whereType<num>()
                .map((value) => value.toDouble())
                .toList(growable: false)
          : const <double>[],
      interpretation: MeihuaInterpretation.tryParse(payload['interpretation']),
      consultationContext: MeihuaConsultationContext.tryParse(
        payload['consultationContext'],
      ),
    );
  }
}
