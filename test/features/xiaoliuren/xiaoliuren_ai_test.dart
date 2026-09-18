import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/features/xiaoliuren/presentation/xiaoliuren_page.dart';

void main() {
  testWidgets('小六壬按当前问题和三宫证据请求远程 AI 解读', (tester) async {
    final service = _RecordingAiService();
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: XiaoliurenPage(
            initialDate: DateTime(2026, 9, 18, 10),
            aiService: service,
            answerStyle: () => 'professional',
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('xiaoliuren-question-input')),
      '这项工作近期能否顺利推进？',
    );
    final calculate = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('xiaoliuren-calculate')),
    );
    calculate.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    final aiButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('xiaoliuren-ai-reading')),
    );
    aiButton.onPressed!();
    await tester.pump();
    await tester.pump();

    expect(service.lastRequest?.question.rawText, '这项工作近期能否顺利推进？');
    expect(service.lastRequest?.answerStyle, 'professional');
    expect(service.lastRequest?.evidence.methodId, 'xiaoliuren');
    expect(find.text('远程 AI · test-model'), findsOneWidget);
    expect(find.textContaining('先完成近期可验证的步骤'), findsOneWidget);
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
      content: '先完成近期可验证的步骤，再根据实际阻力调整推进节奏。',
      source: AiAnswerSource.remote,
      providerId: 'test-provider',
      modelId: 'test-model',
      promptVersion: 2,
      generatedAt: DateTime.utc(2026, 9, 18),
      evidenceMethodId: request.evidence.methodId,
    );
  }
}
