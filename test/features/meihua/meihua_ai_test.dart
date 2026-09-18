import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/features/meihua/presentation/meihua_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('梅花易数按当前问题请求并展示远程 AI 解读', (tester) async {
    await tester.runAsync(HexagramData.load);
    final service = _RecordingAiService();
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeihuaPage(
            aiService: service,
            answerStyle: () => 'professional',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(
      find.byKey(const ValueKey('meihua-question-input')),
      '这项合作接下来应该如何推进？',
    );
    await tester.tap(find.byKey(const ValueKey('meihua-cast')));
    await tester.pump();
    await tester.pump();

    final aiButton = find.byKey(const ValueKey('meihua-ai-reading'));
    await tester.ensureVisible(aiButton);
    await tester.tap(aiButton);
    await tester.pump();
    await tester.pump();

    expect(service.lastRequest?.question.rawText, '这项合作接下来应该如何推进？');
    expect(service.lastRequest?.answerStyle, 'professional');
    expect(service.lastRequest?.evidence.methodId, 'meihua');
    expect(find.text('远程 AI · test-model'), findsOneWidget);
    expect(find.textContaining('先核实合作条件'), findsOneWidget);
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
      content: '先核实合作条件，再约定一个可以验证的小步骤。',
      source: AiAnswerSource.remote,
      providerId: 'test-provider',
      modelId: 'test-model',
      promptVersion: 2,
      generatedAt: DateTime.utc(2026, 9, 18),
      evidenceMethodId: request.evidence.methodId,
    );
  }
}
