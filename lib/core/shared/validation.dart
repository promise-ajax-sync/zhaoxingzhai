/// 验证工具
///
/// 完整移植自 mingyu-core/src/shared/validation.ts
library;

import 'result.dart';

/// 断言可选的 Record/Map
void assertOptionalRecord(dynamic value, String fieldName) {
  if (value == null) return;
  
  if (value is! Map) {
    throw MingyuCoreError(
      code: 'VALIDATION_TYPE_ERROR',
      category: ErrorCategory.validation,
      message: '$fieldName 必须是对象类型',
      field: fieldName,
    );
  }
}

/// 断言非空字符串
String assertNonEmptyString(dynamic value, String fieldName) {
  if (value is! String || value.trim().isEmpty) {
    throw MingyuCoreError(
      code: 'VALIDATION_REQUIRED',
      category: ErrorCategory.validation,
      message: '$fieldName 不能为空',
      field: fieldName,
    );
  }
  return value;
}

/// 断言正整数
int assertPositiveInt(dynamic value, String fieldName) {
  if (value is! int || value <= 0) {
    throw MingyuCoreError(
      code: 'VALIDATION_RANGE_ERROR',
      category: ErrorCategory.validation,
      message: '$fieldName 必须是正整数',
      field: fieldName,
    );
  }
  return value;
}

/// 断言范围内的整数
int assertIntInRange(dynamic value, String fieldName, int min, int max) {
  if (value is! int || value < min || value > max) {
    throw MingyuCoreError(
      code: 'VALIDATION_RANGE_ERROR',
      category: ErrorCategory.validation,
      message: '$fieldName 必须在 $min 到 $max 之间',
      field: fieldName,
    );
  }
  return value;
}

/// 断言有效日期
DateTime assertValidDate(dynamic value, String fieldName) {
  if (value is DateTime) return value;
  
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      throw MingyuCoreError(
        code: 'VALIDATION_DATE_INVALID',
        category: ErrorCategory.validation,
        message: '$fieldName 不是有效的日期格式',
        field: fieldName,
      );
    }
  }
  
  throw MingyuCoreError(
    code: 'VALIDATION_TYPE_ERROR',
    category: ErrorCategory.validation,
    message: '$fieldName 必须是日期类型',
    field: fieldName,
  );
}
