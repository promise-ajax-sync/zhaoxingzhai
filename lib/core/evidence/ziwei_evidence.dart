import 'package:zhaoxingzhai/core/engine/ziwei/ziwei_chart.dart';
import 'package:zhaoxingzhai/core/models/algorithm_metadata.dart';
import 'package:zhaoxingzhai/core/models/divination_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

abstract final class ZiweiEvidenceBuilder {
  static DivinationEvidence build(
    ZiweiChartResult result,
    DivinationQuestion question,
  ) {
    final lifeStars = result.lifePalace.stars
        .map((e) {
          final mutagen = e.mutagen == null ? '' : '化${e.mutagen}';
          final brightness = e.brightness == null ? '' : '（${e.brightness}）';
          return '${e.name}$brightness$mutagen';
        })
        .join('、');
    final transformed = result.palaces
        .expand((e) => e.stars.map((star) => (palace: e, star: star)))
        .where((e) => e.star.mutagen != null)
        .map(
          (e) => '${e.star.name}化${e.star.mutagen}在${e.palace.position.name}',
        )
        .join('、');
    final limit = result.limits.decades.isEmpty
        ? '性别未指定，大限顺逆待确定'
        : '${result.limits.direction.label}，${result.limits.startNominalAge}岁起限';
    final lifeRelations = result.relations.singleWhere((e) => e.source.isLife);
    final firstDecade = result.decadeTransformations.isEmpty
        ? null
        : result.decadeTransformations.first;
    final annual = result.annual;
    return DivinationEvidence(
      methodId: AlgorithmCatalog.ziwei.id,
      version: AlgorithmCatalog.ziwei.version,
      calculationFacts: [
        DivinationEvidenceItem(
          id: 'foundation',
          label: '命身与五行局',
          detail:
              '命宫${result.foundation.lifeBranch}、身宫${result.foundation.bodyBranch}、${result.foundation.fiveElementBureau}',
        ),
        DivinationEvidenceItem(
          id: 'life-palace-stars',
          label: '命宫星曜',
          detail: lifeStars.isEmpty ? '本宫暂无已安置基础星曜' : lifeStars,
        ),
        DivinationEvidenceItem(
          id: 'mutagens',
          label: '生年四化',
          detail: transformed,
        ),
        DivinationEvidenceItem(id: 'limits', label: '大限', detail: limit),
        DivinationEvidenceItem(
          id: 'life-relations',
          label: '命宫三方四正',
          detail:
              '三合${lifeRelations.trines.map((e) => e.name).join('、')}，对宫${lifeRelations.opposite.name}',
        ),
        if (firstDecade != null)
          DivinationEvidenceItem(
            id: 'first-decade-mutagens',
            label: '首限四化',
            detail: firstDecade.placements
                .map((e) => '${e.starName}化${e.mutagen}入${e.destination.name}')
                .join('、'),
          ),
        DivinationEvidenceItem(
          id: 'annual-layer',
          label: '流年层',
          detail:
              '${annual.lunarYear}农历年${annual.yearStem}${annual.yearBranch}，'
              '虚岁${annual.nominalAge}，流年命宫${annual.lifePalace.name}；'
              '${annual.transformations.map((e) => '${e.starName}化${e.mutagen}入${e.destination.name}').join('、')}',
        ),
      ],
      supportingEvidence: [
        DivinationEvidenceItem(
          id: 'year',
          label: '生年干支',
          detail: '${result.yearStem}${result.yearBranch}',
        ),
        DivinationEvidenceItem(
          id: 'brightness-profile',
          label: '庙旺口径',
          detail: result.brightnessProfileId,
        ),
        const DivinationEvidenceItem(
          id: 'star-count',
          label: '星曜范围',
          detail: '当前版本安置 14 主星与 14 辅煮曜',
        ),
      ],
      counterEvidence: const [],
      limitations: const [
        DivinationEvidenceItem(
          id: 'scope',
          label: '解释边界',
          detail: '不凭单星或单宫断定现实事件，不用于医疗、法律或财务决策。',
        ),
        DivinationEvidenceItem(
          id: 'pending-rules',
          label: '未接入规则',
          detail: '庙旺表仅覆盖源表收录的 20 星；流月、流日和流派格局尚未计算，AI 不得自行补全。',
        ),
      ],
      summary:
          '问题：${question.rawText.isEmpty ? '综合解读' : question.rawText}；仅解释程序已计算的紫微盘面事实。',
    );
  }
}
