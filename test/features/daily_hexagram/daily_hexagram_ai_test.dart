import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/features/daily_hexagram/presentation/daily_hexagram_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('每日一卦按当前问题请求并展示远程 AI 解读', (tester) async {
    await tester.runAsync(HexagramData.load);
    final service = _RecordingAiService();
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DailyHexagramPage(
          currentCase: () => null,
          aiService: service,
          answerStyle: () => 'professional',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(
      find.byKey(const ValueKey('daily-hexagram-question-input')),
      '今天工作上应该怎么做',
    );
    await tester.pump();
    final button = find.byKey(const ValueKey('daily-hexagram-ai-reading'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.pump();

    expect(service.lastRequest?.question.rawText, '今天工作上应该怎么做');
    expect(service.lastRequest?.answerStyle, 'professional');
    expect(service.lastRequest?.evidence.methodId, 'daily-hexagram');
    expect(find.text('远程 AI · test-model'), findsOneWidget);
    expect(find.textContaining('先完成今天最重要的事项'), findsOneWidget);
  });
}

class _RecordingAiService implements AiInterpretationService {
  AiInterpretationRequest? lastRequest;

  @override
  Future<AiInterpretationResponse> interpret(
    AiInterpretationRequest request,
  ) async {
    lastRequest = request;
    return AiInterpretationResponse(
      content: '先完成今天最重要的事项，再根据实际反馈调整。',
      source: AiAnswerSource.remote,
      providerId: 'test-provider',
      modelId: 'test-model',
      promptVersion: 2,
      generatedAt: DateTime.utc(2026, 9, 18),
      evidenceMethodId: request.evidence.methodId,
    );
  }
}
