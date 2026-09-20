/// 错误和结果封装
///
/// 昭星斋占测引擎的错误与结果协议。
library;

import 'dart:convert';

import 'package:zhaoxingzhai/core/models/algorithm_metadata.dart';

/// 错误类别
enum ErrorCategory {
  validation, // 验证错误
  calculation, // 计算错误
  notFound, // 未找到
  system, // 系统错误
}

/// 核心错误类
class DivinationEngineError implements Exception {
  final String code;
  final ErrorCategory category;
  final String message;
  final String? field;
  final Map<String, dynamic>? details;

  const DivinationEngineError({
    required this.code,
    required this.category,
    required this.message,
    this.field,
    this.details,
  });

  @override
  String toString() {
    final buffer = StringBuffer('DivinationEngineError: [$code] $message');
    if (field != null) {
      buffer.write(' (field: $field)');
    }
    if (details != null) {
      buffer.write(' details: $details');
    }
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'category': category.name,
    'message': message,
    if (field != null) 'field': field,
    if (details != null) 'details': details,
  };
}

const zhaoxingzhaiEngineVersion = '1.0.0';
const zhaoxingzhaiSchemaVersion = '1.0.0';

/// 昭星斋占测引擎的统一结果元数据。
class ResultMeta {
  final String engineVersion;
  final String schemaVersion;
  final String algorithm;
  final int algorithmVersion;
  final String ruleset;
  final String implementation;
  final String? model;
  final DateTime calculatedAt;
  final String inputHash;
  final String resultId;
  final Map<String, dynamic>? random;

  const ResultMeta({
    required this.engineVersion,
    required this.schemaVersion,
    required this.algorithm,
    required this.algorithmVersion,
    required this.ruleset,
    required this.implementation,
    this.model,
    required this.calculatedAt,
    required this.inputHash,
    required this.resultId,
    this.random,
  });

  Map<String, dynamic> toJson() => {
    'engineVersion': engineVersion,
    'schemaVersion': schemaVersion,
    'algorithm': algorithm,
    'algorithmVersion': algorithmVersion,
    'ruleset': ruleset,
    'implementation': implementation,
    if (model != null) 'model': model,
    'calculatedAt': calculatedAt.toUtc().toIso8601String(),
    'inputHash': inputHash,
    'resultId': resultId,
    if (random != null) 'random': random,
  };
}

dynamic _normalizeStableValue(dynamic value) {
  if (value == null || value is String || value is bool || value is num) {
    return value;
  }
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is List) return value.map(_normalizeStableValue).toList();
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return {for (final key in keys) key: _normalizeStableValue(value[key])};
  }
  throw ArgumentError('结果序列化不支持 ${value.runtimeType} 类型。');
}

String stableStringify(dynamic value) =>
    jsonEncode(_normalizeStableValue(value));

/// FNV-1a 64 位散列，用于结果身份和缓存键，不用于安全签名。
String hashStableValue(dynamic value) {
  final text = stableStringify(value);
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = (BigInt.one << 64) - BigInt.one;
  for (final codeUnit in text.codeUnits) {
    hash ^= BigInt.from(codeUnit);
    hash = (hash * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

ResultMeta createResultMeta({
  required AlgorithmDescriptor descriptor,
  required dynamic input,
  String? model,
  DateTime? calculatedAt,
  Map<String, dynamic>? random,
}) {
  final normalizedAlgorithm = descriptor.id.trim();
  if (normalizedAlgorithm.isEmpty) {
    throw ArgumentError('结果元数据必须提供算法标识。');
  }
  final inputHash = hashStableValue(input);
  final identityHash = hashStableValue({
    'algorithm': normalizedAlgorithm,
    'algorithmVersion': descriptor.version,
    'ruleset': descriptor.ruleset,
    'implementation': descriptor.implementation,
    'engineVersion': zhaoxingzhaiEngineVersion,
    'schemaVersion': zhaoxingzhaiSchemaVersion,
    ...model == null ? const {} : {'model': model},
    'inputHash': inputHash,
    ...random == null ? const {} : {'randomSamples': random['samples']},
  });
  return ResultMeta(
    engineVersion: zhaoxingzhaiEngineVersion,
    schemaVersion: zhaoxingzhaiSchemaVersion,
    algorithm: normalizedAlgorithm,
    algorithmVersion: descriptor.version,
    ruleset: descriptor.ruleset,
    implementation: descriptor.implementation,
    model: model,
    calculatedAt: calculatedAt ?? DateTime.now().toUtc(),
    inputHash: inputHash,
    resultId: '$normalizedAlgorithm:$identityHash',
    random: random,
  );
}
