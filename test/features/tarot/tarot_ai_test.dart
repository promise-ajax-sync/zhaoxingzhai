import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/data/tarot_data.dart';
import 'package:zhaoxingzhai/features/tarot/presentation/tarot_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('塔罗按当前问题和牌阵证据请求远程 AI 解读', (tester) async {
    await tester.runAsync(TarotData.load);
    final service = _RecordingAiService();
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TarotPage(
            aiService: service,
            answerStyle: () => 'professional',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(
      find.byKey(const ValueKey('tarot-question-input')),
      '这段关系接下来应该如何沟通？',
    );
    final drawButton = find.byKey(const ValueKey('tarot-draw-cards'));
    final drawWidget = tester.widget<ElevatedButton>(drawButton);
    drawWidget.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final aiButton = find.byKey(const ValueKey('tarot-ai-reading'));
    final aiWidget = tester.widget<FilledButton>(aiButton);
    aiWidget.onPressed!();
    await tester.pump();
    await tester.pump();

    expect(service.lastRequest?.question.rawText, '这段关系接下来应该如何沟通？');
    expect(service.lastRequest?.answerStyle, 'professional');
    expect(service.lastRequest?.evidence.methodId, 'tarot');
    expect(find.text('远程 AI · test-model'), findsOneWidget);
    expect(find.textContaining('先确认双方真正关心的事项'), findsOneWidget);
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
      content: '先确认双方真正关心的事项，再安排一次边界清楚的沟通。',
      source: AiAnswerSource.remote,
      providerId: 'test-provider',
      modelId: 'test-model',
      promptVersion: 2,
      generatedAt: DateTime.utc(2026, 9, 18),
      evidenceMethodId: request.evidence.methodId,
    );
  }
}
