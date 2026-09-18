class AiBackendConfig {
  const AiBackendConfig({
    required this.baseUrl,
    this.interpretPath = '/api/v1/interpret',
  });

  factory AiBackendConfig.fromEnvironment() => const AiBackendConfig(
    baseUrl: String.fromEnvironment(
      'AI_BACKEND_URL',
      defaultValue: 'http://127.0.0.1:8000',
    ),
  );

  final String baseUrl;
  final String interpretPath;

  Uri get interpretUri {
    final normalizedBase = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final normalizedPath = interpretPath.startsWith('/')
        ? interpretPath
        : '/$interpretPath';
    final uri = Uri.tryParse('$normalizedBase$normalizedPath');
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw FormatException('AI 后端地址无效：$baseUrl');
    }
    return uri;
  }
}
