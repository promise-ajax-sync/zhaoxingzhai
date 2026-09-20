import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

QueryExecutor openAppDatabase() {
  const compileTimeTest = bool.fromEnvironment('FLUTTER_TEST');
  final isFlutterTest =
      compileTimeTest || Platform.environment['FLUTTER_TEST'] == 'true';
  if (isFlutterTest) {
    return NativeDatabase.memory();
  }
  return driftDatabase(name: 'zhaoxingzhai');
}
