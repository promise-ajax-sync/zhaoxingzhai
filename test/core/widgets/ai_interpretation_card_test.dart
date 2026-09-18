import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/widgets/ai_interpretation_card.dart';

void main() {
  testWidgets('AI 公共卡片展示远程模型和回答', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiInterpretationCard(
            response: AiInterpretationResponse(
              content: '这是针对当前问题的回答。',
              source: AiAnswerSource.remote,
              providerId: 'test-provider',
              modelId: 'test-model',
              promptVersion: 2,
              generatedAt: DateTime.utc(2026, 9, 18),
              evidenceMethodId: 'tarot',
            ),
            loading: false,
            error: null,
            onRequest: () async {},
            loadingText: '正在生成…',
            idleText: '等待生成',
            actionKey: const ValueKey('test-ai-action'),
          ),
        ),
      ),
    );

    expect(find.text('远程 AI · test-model'), findsOneWidget);
    expect(find.text('这是针对当前问题的回答。'), findsOneWidget);
    expect(find.textContaining('提示词 v2'), findsOneWidget);
    expect(find.byKey(const ValueKey('test-ai-action')), findsOneWidget);
  });

  testWidgets('AI 公共卡片使用面向用户的降级文案', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiInterpretationCard(
            response: AiInterpretationResponse(
              content: '当前显示基础解读。',
              source: AiAnswerSource.localFallback,
              providerId: 'local',
              modelId: 'local-v2',
              promptVersion: 2,
              generatedAt: DateTime.utc(2026, 9, 18),
              evidenceMethodId: 'ssgw',
              fallbackReason: '网络不可用',
            ),
            loading: false,
            error: null,
            onRequest: () async {},
            loadingText: '正在生成…',
            idleText: '等待生成',
            actionKey: const ValueKey('test-fallback-action'),
          ),
        ),
      ),
    );

    expect(find.text('基础解读（智能服务暂不可用）'), findsOneWidget);
    expect(find.textContaining('网络不可用'), findsOneWidget);
  });
}
