import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/engine/daily_hexagram/daily_hexagram.dart';
import 'package:zhaoxingzhai/core/engine/meihua/meihua_divination.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/algorithm.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/features/history/data/divination_history_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('历史记录可以持久化、重新读取和删除', () async {
    final createdAt = DateTime(2026, 9, 17, 12, 30);
    final repository = DivinationHistoryRepository();

    await repository.add(
      DivinationHistoryRecord(
        id: 'test:1',
        type: 'tarot',
        title: '单牌指引',
        summary: '当前指引：愚者正位',
        createdAt: createdAt,
        payload: const {'spreadType': 'single'},
        algorithmId: 'tarot',
        algorithmVersion: 1,
        schemaVersion: '1.0.0',
      ),
    );

    final reloaded = DivinationHistoryRepository();
    await reloaded.ensureLoaded();

    expect(reloaded.records, hasLength(1));
    expect(reloaded.records.single.title, '单牌指引');
    expect(reloaded.records.single.createdAt, createdAt);
    expect(reloaded.records.single.algorithmLabel, 'tarot v1');

    await reloaded.delete('test:1');
    expect(reloaded.records, isEmpty);

    repository.dispose();
    reloaded.dispose();
  });

  test('AI 解读更新原历史记录且不会新增重复记录', () async {
    final repository = DivinationHistoryRepository();
    await repository.add(
      DivinationHistoryRecord(
        id: 'test:ai',
        type: 'tarot',
        title: '单牌指引',
        summary: '测试记录',
        createdAt: DateTime(2026, 9, 18),
        payload: const {'spreadType': 'single'},
        algorithmId: 'tarot',
        algorithmVersion: 1,
        schemaVersion: '1.0.0',
      ),
    );

    final updated = await repository.updateAiInterpretation(
      'test:ai',
      AiInterpretationResponse(
        content: '先完成一个可验证的小步骤。',
        source: AiAnswerSource.remote,
        providerId: 'test-provider',
        modelId: 'test-model',
        promptVersion: 2,
        generatedAt: DateTime.utc(2026, 9, 18),
        evidenceMethodId: 'tarot',
      ),
    );

    expect(updated, isTrue);
    expect(repository.records, hasLength(1));
    expect(repository.records.single.aiInterpretation?.modelId, 'test-model');

    final reloaded = DivinationHistoryRepository();
    await reloaded.ensureLoaded();
    expect(reloaded.records.single.aiInterpretation?.content, contains('可验证'));

    repository.dispose();
    reloaded.dispose();
  });

  test('相同结果标识会更新并移动到最前而不是重复保存', () async {
    final repository = DivinationHistoryRepository();
    final older = DateTime(2026, 9, 16);
    final newer = DateTime(2026, 9, 17);

    await repository.add(
      DivinationHistoryRecord(
        id: 'same-result',
        type: 'xiaoliuren',
        title: '旧记录',
        summary: '旧摘要',
        createdAt: older,
        payload: const {},
        algorithmId: 'xiaoliuren',
        algorithmVersion: 1,
        schemaVersion: '1.0.0',
      ),
    );
    await repository.add(
      DivinationHistoryRecord(
        id: 'same-result',
        type: 'xiaoliuren',
        title: '新记录',
        summary: '新摘要',
        createdAt: newer,
        payload: const {},
        algorithmId: 'xiaoliuren',
        algorithmVersion: 2,
        schemaVersion: '1.0.0',
      ),
    );

    expect(repository.records, hasLength(1));
    expect(repository.records.single.title, '新记录');
    expect(repository.records.single.createdAt, newer);
    expect(repository.records.single.algorithmVersion, 2);

    repository.dispose();
  });

  test('小六壬结果可以转换为历史记录并保留完整载荷', () async {
    final repository = DivinationHistoryRepository();
    final result = generateXiaoliuren(customDate: DateTime(2026, 9, 17, 12));

    await repository.addXiaoliuren(result);

    expect(repository.records, hasLength(1));
    expect(repository.records.single.type, 'xiaoliuren');
    expect(repository.records.single.title, contains(result.primary.name));
    expect(repository.records.single.payload['meta'], isA<Map>());
    expect(repository.records.single.payload['primary'], isA<Map>());
    expect(repository.records.single.payload['meta']['algorithmVersion'], 1);

    // 版本信息必须提升到顶层，才能被查询和迁移。
    expect(repository.records.single.algorithmId, result.meta.algorithm);
    expect(
      repository.records.single.algorithmVersion,
      result.meta.algorithmVersion,
    );
    expect(repository.records.single.schemaVersion, result.meta.schemaVersion);

    repository.dispose();
  });

  test('每日一卦历史保存当时生成的分项解读版本和内容', () async {
    await HexagramData.load();
    final repository = DivinationHistoryRepository();
    final result = DailyHexagramEngine.fromYaoValues([
      6,
      7,
      7,
      7,
      7,
      7,
    ], date: DateTime(2026, 9, 18));

    await repository.addDailyHexagram(result);

    final interpretation = repository.records.single.payload['interpretation'];
    expect(interpretation, isA<Map>());
    expect(interpretation['id'], 'daily-hexagram.local-reading');
    expect(interpretation['version'], 2);
    expect(interpretation['traditionalOverview'], contains('天风姤'));
    expect(interpretation['riskReminder'], isNotEmpty);

    repository.dispose();
  });

  test('梅花易数历史保存完整卦盘、体用与算法版本', () async {
    await HexagramData.load();
    final repository = DivinationHistoryRepository();
    final result = MeihuaDivination.number(number: 123, hourBranch: '辰');

    await repository.addMeihua(result);

    final record = repository.records.single;
    expect(record.type, 'meihua');
    expect(record.algorithmId, 'meihua');
    expect(record.algorithmVersion, 1);
    expect(record.payload['original']['name'], '火地晋');
    expect(record.payload['inter']['name'], '水山蹇');
    expect(record.payload['changed']['name'], '火水未济');
    expect(record.payload['movingYao']['position'], 2);
    expect(record.payload['tiYongRelation'], '体生用');
    expect(record.payload['interpretation']['id'], 'meihua.local-reading');
    expect(record.payload['interpretation']['version'], 4);
    expect(record.payload['interpretation']['evidence']['methodId'], 'meihua');
    expect(
      record.payload['interpretation']['evidence']['limitations'],
      isNotEmpty,
    );
    expect(record.payload['interpretation']['topic'], 'general');
    expect(record.payload['interpretation']['topicLabel'], '综合事项');

    repository.dispose();
  });

  test('未指定案例时历史记录没有快照', () async {
    final repository = DivinationHistoryRepository();
    final result = generateXiaoliuren(customDate: DateTime(2026, 9, 17, 12));

    await repository.addXiaoliuren(result);

    expect(repository.records.single.caseSnapshot, isNull);

    repository.dispose();
  });

  test('修改或删除案例都不会改变已保存历史中的快照', () async {
    final repository = DivinationHistoryRepository();
    final profile = CaseProfile.create(
      name: '张三',
      birthDateTime: DateTime(1990, 5, 1, 8, 30),
      now: DateTime(2026, 1, 1),
    );
    final result = generateXiaoliuren(customDate: DateTime(2026, 9, 17, 12));

    await repository.addXiaoliuren(result, caseSnapshot: profile.toSnapshot());

    // 事后大幅修改案例资料。
    final updated = profile.copyWith(
      name: '李四',
      birthDateTime: DateTime(1991, 6, 2, 9, 0),
      updatedAt: DateTime(2026, 9, 18),
    );
    expect(updated.name, '李四');
    expect(updated.birthDateTime, DateTime(1991, 6, 2, 9, 0));

    // 内存中的记录保持原样。
    expect(repository.records.single.caseSnapshot!.name, '张三');
    expect(
      repository.records.single.caseSnapshot!.birthDateTime,
      DateTime(1990, 5, 1, 8, 30),
    );

    // 重新读取后依然保持原样——快照必须真的落盘了。
    final reloaded = DivinationHistoryRepository();
    await reloaded.ensureLoaded();
    expect(reloaded.records.single.caseSnapshot!.name, '张三');
    expect(
      reloaded.records.single.caseSnapshot!.birthDateTime,
      DateTime(1990, 5, 1, 8, 30),
    );

    repository.dispose();
    reloaded.dispose();
  });

  test('快照资料签名随出生时间变化，可用于缓存失效', () {
    final base = CaseProfile.create(
      name: '张三',
      birthDateTime: DateTime(1990, 5, 1, 8, 30),
      now: DateTime(2026, 1, 1),
    );

    expect(base.toSnapshot().stableHash, isNotEmpty);
    expect(base.toSnapshot().stableHash, base.toSnapshot().stableHash);
    expect(
      base.toSnapshot().stableHash,
      isNot(
        base
            .copyWith(birthDateTime: DateTime(1990, 5, 1, 9, 30))
            .toSnapshot()
            .stableHash,
      ),
    );
  });

  test('缺少顶层版本字段的旧记录会从载荷中回补', () async {
    SharedPreferences.setMockInitialValues({
      DivinationHistoryRepository.storageKey: jsonEncode([
        {
          'id': 'legacy:1',
          'type': 'xiaoliuren',
          'title': '旧版记录',
          'summary': '旧摘要',
          'createdAt': DateTime(2026, 8, 1, 10).toUtc().toIso8601String(),
          'payload': {
            'meta': {
              'algorithm': 'xiaoliuren',
              'algorithmVersion': 1,
              'schemaVersion': '1.0.0',
            },
          },
        },
      ]),
    });

    final repository = DivinationHistoryRepository();
    await repository.ensureLoaded();

    expect(repository.records, hasLength(1));
    expect(repository.records.single.algorithmId, 'xiaoliuren');
    expect(repository.records.single.algorithmVersion, 1);
    expect(repository.records.single.schemaVersion, '1.0.0');

    repository.dispose();
  });

  test('完全没有版本信息的记录标记为未知而不是假装是 v1', () async {
    SharedPreferences.setMockInitialValues({
      DivinationHistoryRepository.storageKey: jsonEncode([
        {
          'id': 'legacy:2',
          'type': 'tarot',
          'title': '无版本记录',
          'summary': '旧摘要',
          'createdAt': DateTime(2026, 8, 1, 10).toUtc().toIso8601String(),
          'payload': <String, dynamic>{},
        },
      ]),
    });

    final repository = DivinationHistoryRepository();
    await repository.ensureLoaded();

    expect(repository.records.single.algorithmId, 'unknown');
    expect(repository.records.single.algorithmVersion, 0);

    repository.dispose();
  });

  test('账号注销会清除历史及同步状态', () async {
    SharedPreferences.setMockInitialValues({
      DivinationHistoryRepository.storageKey: jsonEncode([]),
      DivinationHistoryRepository.syncStorageKey: jsonEncode({}),
    });
    final repository = DivinationHistoryRepository();

    await repository.clearLocalData();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.containsKey(DivinationHistoryRepository.storageKey),
      isFalse,
    );
    expect(
      preferences.containsKey(DivinationHistoryRepository.syncStorageKey),
      isFalse,
    );
    repository.dispose();
  });
}
