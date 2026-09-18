import 'package:http/http.dart' as http;
import 'package:zhaoxingzhai/core/ai/ai_backend_config.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/ai/backend_ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/ai/local_ai_interpretation_service.dart';

class AiServiceBundle {
  AiServiceBundle(this.service, this._client);

  final AiInterpretationService service;
  final http.Client _client;

  void dispose() => _client.close();
}

abstract final class AiServiceFactory {
  static AiServiceBundle create({
    AiBackendConfig? config,
    Duration timeout = const Duration(seconds: 90),
  }) {
    final client = http.Client();
    final backend = BackendAiInterpretationService(
      client,
      config ?? AiBackendConfig.fromEnvironment(),
    );
    return AiServiceBundle(
      ResilientAiInterpretationService(
        primary: backend,
        fallback: const LocalAiInterpretationService(),
        timeout: timeout,
      ),
      client,
    );
  }
}
