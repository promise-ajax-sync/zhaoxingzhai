import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zhaoxingzhai/core/ai/ai_backend_config.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';

class AiBackendException implements Exception {
  const AiBackendException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => statusCode == null
      ? 'AiBackendException: $message'
      : 'AiBackendException($statusCode): $message';
}

class BackendAiInterpretationService implements AiInterpretationService {
  const BackendAiInterpretationService(this._client, this._config);

  final http.Client _client;
  final AiBackendConfig _config;

  @override
  Future<AiInterpretationResponse> interpret(
    AiInterpretationRequest request,
  ) async {
    final response = await _client.post(
      _config.interpretUri,
      headers: const {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );
    final decoded = _decodeJson(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiBackendException(
        _errorMessage(decoded, response.statusCode),
        statusCode: response.statusCode,
      );
    }
    final result = AiInterpretationResponse.tryParse(decoded);
    if (result == null) {
      throw const AiBackendException('AI 后端返回格式无效');
    }
    return result;
  }

  static Object? _decodeJson(List<int> bodyBytes) {
    try {
      return jsonDecode(utf8.decode(bodyBytes));
    } catch (_) {
      return null;
    }
  }

  static String _errorMessage(Object? decoded, int statusCode) {
    if (decoded is Map) {
      final detail = decoded['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
      final error = decoded['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error.trim();
      }
    }
    return switch (statusCode) {
      400 => '请求内容无效',
      401 || 403 => 'AI 后端拒绝了请求',
      429 => 'AI 请求过于频繁，请稍后再试',
      >= 500 => 'AI 后端暂时不可用',
      _ => 'AI 请求失败',
    };
  }
}
