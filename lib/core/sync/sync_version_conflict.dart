class SyncVersionConflict implements Exception {
  const SyncVersionConflict({required this.resource, this.currentVersion});

  final String resource;
  final int? currentVersion;

  @override
  String toString() => '云端版本冲突：$resource';
}
