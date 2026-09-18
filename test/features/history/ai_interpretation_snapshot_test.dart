import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/features/history/data/ai_interpretation_snapshot.dart';

void main() {
  test('AI 解读快照可序列化并兼容降级元数据', () {
    final response = AiInterpretationResponse(
      content: '先完成一个可验证的小步骤。',
      source: AiAnswerSource.localFallback,
      providerId: 'local',
      modelId: 'local-v2',
      promptVersion: 2,
      generatedAt: DateTime.utc(2026, 9, 18),
      evidenceMethodId: 'tarot',
      fallbackReason: '网络不可用',
    );
    final snapshot = AiInterpretationSnapshot.fromResponse(
      response,
      answerStyle: 'professional',
    );
    final restored = AiInterpretationSnapshot.tryParse(snapshot.toJson());

    expect(restored?.content, response.content);
    expect(restored?.source, AiAnswerSource.localFallback);
    expect(restored?.modelId, 'local-v2');
    expect(restored?.fallbackReason, '网络不可用');
    expect(restored?.answerStyle, 'professional');
  });
}
