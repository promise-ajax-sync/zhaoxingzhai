enum HistorySyncStatus {
  localOnly,
  pending,
  syncing,
  synced,
  failed,
  pendingDelete,
}

class HistorySyncState {
  const HistorySyncState({
    required this.recordId,
    required this.status,
    this.serverRecordId,
    this.retryCount = 0,
    this.nextRetryAt,
    this.lastSyncedAt,
    this.lastError,
  });

  final String recordId;
  final HistorySyncStatus status;
  final String? serverRecordId;
  final int retryCount;
  final DateTime? nextRetryAt;
  final DateTime? lastSyncedAt;
  final String? lastError;

  HistorySyncState copyWith({
    HistorySyncStatus? status,
    String? serverRecordId,
    int? retryCount,
    DateTime? nextRetryAt,
    DateTime? lastSyncedAt,
    String? lastError,
    bool clearNextRetry = false,
    bool clearError = false,
  }) => HistorySyncState(
    recordId: recordId,
    status: status ?? this.status,
    serverRecordId: serverRecordId ?? this.serverRecordId,
    retryCount: retryCount ?? this.retryCount,
    nextRetryAt: clearNextRetry ? null : nextRetryAt ?? this.nextRetryAt,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    lastError: clearError ? null : lastError ?? this.lastError,
  );

  Map<String, dynamic> toJson() => {
    'recordId': recordId,
    'status': status.name,
    if (serverRecordId != null) 'serverRecordId': serverRecordId,
    'retryCount': retryCount,
    if (nextRetryAt != null)
      'nextRetryAt': nextRetryAt!.toUtc().toIso8601String(),
    if (lastSyncedAt != null)
      'lastSyncedAt': lastSyncedAt!.toUtc().toIso8601String(),
    if (lastError != null) 'lastError': lastError,
  };

  static HistorySyncState? tryParse(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final recordId = raw['recordId'];
    final statusName = raw['status'];
    if (recordId is! String || statusName is! String) {
      return null;
    }
    HistorySyncStatus? status;
    for (final candidate in HistorySyncStatus.values) {
      if (candidate.name == statusName) {
        status = candidate;
        break;
      }
    }
    if (status == null) {
      return null;
    }
    DateTime? parseDate(Object? value) =>
        value is String ? DateTime.tryParse(value)?.toLocal() : null;
    return HistorySyncState(
      recordId: recordId,
      status: status,
      serverRecordId: raw['serverRecordId'] as String?,
      retryCount: (raw['retryCount'] as num?)?.toInt() ?? 0,
      nextRetryAt: parseDate(raw['nextRetryAt']),
      lastSyncedAt: parseDate(raw['lastSyncedAt']),
      lastError: raw['lastError'] as String?,
    );
  }
}
