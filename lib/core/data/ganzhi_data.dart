/// 干支数据加载器
library;

import 'dart:convert';
import 'package:flutter/services.dart';

/// 干支数据加载器
class GanzhiData {
  static List<String>? _tiangan;
  static List<String>? _dizhi;

  /// 加载干支数据
  static Future<void> load() async {
    if (_tiangan != null && _dizhi != null) return;

    final jsonString = await rootBundle.loadString('assets/data/ganzhi.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    _tiangan = (json['tiangan'] as List).cast<String>();
    _dizhi = (json['dizhi'] as List).cast<String>();
  }

  /// 获取天干
  static List<String> get tiangan {
    if (_tiangan == null) {
      throw StateError('GanzhiData not loaded. Call GanzhiData.load() first.');
    }
    return _tiangan!;
  }

  /// 获取地支
  static List<String> get dizhi {
    if (_dizhi == null) {
      throw StateError('GanzhiData not loaded. Call GanzhiData.load() first.');
    }
    return _dizhi!;
  }

  /// 根据索引获取天干
  static String getTiangan(int index) {
    return tiangan[index % 10];
  }

  /// 根据索引获取地支
  static String getDizhi(int index) {
    return dizhi[index % 12];
  }

  /// 生成六十甲子
  static List<String> get sixtyJiazi {
    final result = <String>[];
    for (int i = 0; i < 60; i++) {
      result.add('${getTiangan(i)}${getDizhi(i)}');
    }
    return result;
  }
}
