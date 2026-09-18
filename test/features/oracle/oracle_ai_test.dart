import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/data/ssgw_data.dart';
import 'package:zhaoxingzhai/features/oracle/presentation/oracle_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('灵签按当前问题和签文证据请求远程 AI 解读', (tester) async {
    await tester.runAsync(SsgwData.load);
    final service = _RecordingAiService();
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OraclePage(
            aiService: service,
            answerStyle: () => 'professional',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(
      find.byKey(const ValueKey('ssgw-question-input')),
      '这个合作方案是否适合继续推进？',
    );
    await tester.enterText(
      find.byKey(const ValueKey('ssgw-sign-number-input')),
      '1',
    );
    final resolve = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('ssgw-resolve')),
    );
    resolve.onPressed!();
    await tester.pump();

    final aiButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('ssgw-ai-reading')),
    );
    aiButton.onPressed!();
    await tester.pump();
    await tester.pump();

    expect(service.lastRequest?.question.rawText, '这个合作方案是否适合继续推进？');
    expect(service.lastRequest?.answerStyle, 'professional');
    expect(service.lastRequest?.evidence.methodId, 'ssgw');
    expect(find.text('远程 AI · test-model'), findsOneWidget);
    expect(find.textContaining('先核对合作条件'), findsOneWidget);
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
      content: '先核对合作条件与退出边界，再用一个小范围步骤验证可行性。',
      source: AiAnswerSource.remote,
      providerId: 'test-provider',
      modelId: 'test-model',
      promptVersion: 2,
      generatedAt: DateTime.utc(2026, 9, 18),
      evidenceMethodId: request.evidence.methodId,
    );
  }
}
