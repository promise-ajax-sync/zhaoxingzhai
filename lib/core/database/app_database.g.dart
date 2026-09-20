// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalCasesTable extends LocalCases
    with TableInfo<$LocalCasesTable, LocalCase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileJsonMeta = const VerificationMeta(
    'profileJson',
  );
  @override
  late final GeneratedColumn<String> profileJson = GeneratedColumn<String>(
    'profile_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, profileJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_cases';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_json')) {
      context.handle(
        _profileJsonMeta,
        profileJson.isAcceptableOrUnknown(
          data['profile_json']!,
          _profileJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_profileJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalCasesTable createAlias(String alias) {
    return $LocalCasesTable(attachedDatabase, alias);
  }
}

class LocalCase extends DataClass implements Insertable<LocalCase> {
  final String id;
  final String profileJson;
  final DateTime updatedAt;
  const LocalCase({
    required this.id,
    required this.profileJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_json'] = Variable<String>(profileJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalCasesCompanion toCompanion(bool nullToAbsent) {
    return LocalCasesCompanion(
      id: Value(id),
      profileJson: Value(profileJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalCase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCase(
      id: serializer.fromJson<String>(json['id']),
      profileJson: serializer.fromJson<String>(json['profileJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileJson': serializer.toJson<String>(profileJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalCase copyWith({String? id, String? profileJson, DateTime? updatedAt}) =>
      LocalCase(
        id: id ?? this.id,
        profileJson: profileJson ?? this.profileJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalCase copyWithCompanion(LocalCasesCompanion data) {
    return LocalCase(
      id: data.id.present ? data.id.value : this.id,
      profileJson: data.profileJson.present
          ? data.profileJson.value
          : this.profileJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCase(')
          ..write('id: $id, ')
          ..write('profileJson: $profileJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCase &&
          other.id == this.id &&
          other.profileJson == this.profileJson &&
          other.updatedAt == this.updatedAt);
}

class LocalCasesCompanion extends UpdateCompanion<LocalCase> {
  final Value<String> id;
  final Value<String> profileJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalCasesCompanion({
    this.id = const Value.absent(),
    this.profileJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCasesCompanion.insert({
    required String id,
    required String profileJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileJson = Value(profileJson),
       updatedAt = Value(updatedAt);
  static Insertable<LocalCase> custom({
    Expression<String>? id,
    Expression<String>? profileJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileJson != null) 'profile_json': profileJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCasesCompanion copyWith({
    Value<String>? id,
    Value<String>? profileJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalCasesCompanion(
      id: id ?? this.id,
      profileJson: profileJson ?? this.profileJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileJson.present) {
      map['profile_json'] = Variable<String>(profileJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCasesCompanion(')
          ..write('id: $id, ')
          ..write('profileJson: $profileJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCaseSyncStatesTable extends LocalCaseSyncStates
    with TableInfo<$LocalCaseSyncStatesTable, LocalCaseSyncState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCaseSyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendingDeleteServerIdMeta =
      const VerificationMeta('pendingDeleteServerId');
  @override
  late final GeneratedColumn<String> pendingDeleteServerId =
      GeneratedColumn<String>(
        'pending_delete_server_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    serverId,
    pendingDeleteServerId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_case_sync_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCaseSyncState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('pending_delete_server_id')) {
      context.handle(
        _pendingDeleteServerIdMeta,
        pendingDeleteServerId.isAcceptableOrUnknown(
          data['pending_delete_server_id']!,
          _pendingDeleteServerIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  LocalCaseSyncState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCaseSyncState(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      pendingDeleteServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pending_delete_server_id'],
      ),
    );
  }

  @override
  $LocalCaseSyncStatesTable createAlias(String alias) {
    return $LocalCaseSyncStatesTable(attachedDatabase, alias);
  }
}

class LocalCaseSyncState extends DataClass
    implements Insertable<LocalCaseSyncState> {
  final String localId;
  final String? serverId;
  final String? pendingDeleteServerId;
  const LocalCaseSyncState({
    required this.localId,
    this.serverId,
    this.pendingDeleteServerId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    if (!nullToAbsent || pendingDeleteServerId != null) {
      map['pending_delete_server_id'] = Variable<String>(pendingDeleteServerId);
    }
    return map;
  }

  LocalCaseSyncStatesCompanion toCompanion(bool nullToAbsent) {
    return LocalCaseSyncStatesCompanion(
      localId: Value(localId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      pendingDeleteServerId: pendingDeleteServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingDeleteServerId),
    );
  }

  factory LocalCaseSyncState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCaseSyncState(
      localId: serializer.fromJson<String>(json['localId']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      pendingDeleteServerId: serializer.fromJson<String?>(
        json['pendingDeleteServerId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'serverId': serializer.toJson<String?>(serverId),
      'pendingDeleteServerId': serializer.toJson<String?>(
        pendingDeleteServerId,
      ),
    };
  }

  LocalCaseSyncState copyWith({
    String? localId,
    Value<String?> serverId = const Value.absent(),
    Value<String?> pendingDeleteServerId = const Value.absent(),
  }) => LocalCaseSyncState(
    localId: localId ?? this.localId,
    serverId: serverId.present ? serverId.value : this.serverId,
    pendingDeleteServerId: pendingDeleteServerId.present
        ? pendingDeleteServerId.value
        : this.pendingDeleteServerId,
  );
  LocalCaseSyncState copyWithCompanion(LocalCaseSyncStatesCompanion data) {
    return LocalCaseSyncState(
      localId: data.localId.present ? data.localId.value : this.localId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      pendingDeleteServerId: data.pendingDeleteServerId.present
          ? data.pendingDeleteServerId.value
          : this.pendingDeleteServerId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCaseSyncState(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('pendingDeleteServerId: $pendingDeleteServerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, serverId, pendingDeleteServerId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCaseSyncState &&
          other.localId == this.localId &&
          other.serverId == this.serverId &&
          other.pendingDeleteServerId == this.pendingDeleteServerId);
}

class LocalCaseSyncStatesCompanion extends UpdateCompanion<LocalCaseSyncState> {
  final Value<String> localId;
  final Value<String?> serverId;
  final Value<String?> pendingDeleteServerId;
  final Value<int> rowid;
  const LocalCaseSyncStatesCompanion({
    this.localId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.pendingDeleteServerId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCaseSyncStatesCompanion.insert({
    required String localId,
    this.serverId = const Value.absent(),
    this.pendingDeleteServerId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId);
  static Insertable<LocalCaseSyncState> custom({
    Expression<String>? localId,
    Expression<String>? serverId,
    Expression<String>? pendingDeleteServerId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (serverId != null) 'server_id': serverId,
      if (pendingDeleteServerId != null)
        'pending_delete_server_id': pendingDeleteServerId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCaseSyncStatesCompanion copyWith({
    Value<String>? localId,
    Value<String?>? serverId,
    Value<String?>? pendingDeleteServerId,
    Value<int>? rowid,
  }) {
    return LocalCaseSyncStatesCompanion(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      pendingDeleteServerId:
          pendingDeleteServerId ?? this.pendingDeleteServerId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (pendingDeleteServerId.present) {
      map['pending_delete_server_id'] = Variable<String>(
        pendingDeleteServerId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCaseSyncStatesCompanion(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('pendingDeleteServerId: $pendingDeleteServerId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalHistoryRecordsTable extends LocalHistoryRecords
    with TableInfo<$LocalHistoryRecordsTable, LocalHistoryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalHistoryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordJsonMeta = const VerificationMeta(
    'recordJson',
  );
  @override
  late final GeneratedColumn<String> recordJson = GeneratedColumn<String>(
    'record_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, recordJson, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_history_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalHistoryRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('record_json')) {
      context.handle(
        _recordJsonMeta,
        recordJson.isAcceptableOrUnknown(data['record_json']!, _recordJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_recordJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalHistoryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalHistoryRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recordJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalHistoryRecordsTable createAlias(String alias) {
    return $LocalHistoryRecordsTable(attachedDatabase, alias);
  }
}

class LocalHistoryRecord extends DataClass
    implements Insertable<LocalHistoryRecord> {
  final String id;
  final String recordJson;
  final DateTime createdAt;
  const LocalHistoryRecord({
    required this.id,
    required this.recordJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['record_json'] = Variable<String>(recordJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalHistoryRecordsCompanion toCompanion(bool nullToAbsent) {
    return LocalHistoryRecordsCompanion(
      id: Value(id),
      recordJson: Value(recordJson),
      createdAt: Value(createdAt),
    );
  }

  factory LocalHistoryRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalHistoryRecord(
      id: serializer.fromJson<String>(json['id']),
      recordJson: serializer.fromJson<String>(json['recordJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recordJson': serializer.toJson<String>(recordJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalHistoryRecord copyWith({
    String? id,
    String? recordJson,
    DateTime? createdAt,
  }) => LocalHistoryRecord(
    id: id ?? this.id,
    recordJson: recordJson ?? this.recordJson,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalHistoryRecord copyWithCompanion(LocalHistoryRecordsCompanion data) {
    return LocalHistoryRecord(
      id: data.id.present ? data.id.value : this.id,
      recordJson: data.recordJson.present
          ? data.recordJson.value
          : this.recordJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalHistoryRecord(')
          ..write('id: $id, ')
          ..write('recordJson: $recordJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recordJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalHistoryRecord &&
          other.id == this.id &&
          other.recordJson == this.recordJson &&
          other.createdAt == this.createdAt);
}

class LocalHistoryRecordsCompanion extends UpdateCompanion<LocalHistoryRecord> {
  final Value<String> id;
  final Value<String> recordJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalHistoryRecordsCompanion({
    this.id = const Value.absent(),
    this.recordJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalHistoryRecordsCompanion.insert({
    required String id,
    required String recordJson,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recordJson = Value(recordJson),
       createdAt = Value(createdAt);
  static Insertable<LocalHistoryRecord> custom({
    Expression<String>? id,
    Expression<String>? recordJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordJson != null) 'record_json': recordJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalHistoryRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? recordJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalHistoryRecordsCompanion(
      id: id ?? this.id,
      recordJson: recordJson ?? this.recordJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recordJson.present) {
      map['record_json'] = Variable<String>(recordJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalHistoryRecordsCompanion(')
          ..write('id: $id, ')
          ..write('recordJson: $recordJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalHistorySyncStatesTable extends LocalHistorySyncStates
    with TableInfo<$LocalHistorySyncStatesTable, LocalHistorySyncState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalHistorySyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateJsonMeta = const VerificationMeta(
    'stateJson',
  );
  @override
  late final GeneratedColumn<String> stateJson = GeneratedColumn<String>(
    'state_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [recordId, stateJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_history_sync_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalHistorySyncState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('state_json')) {
      context.handle(
        _stateJsonMeta,
        stateJson.isAcceptableOrUnknown(data['state_json']!, _stateJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_stateJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recordId};
  @override
  LocalHistorySyncState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalHistorySyncState(
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      stateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state_json'],
      )!,
    );
  }

  @override
  $LocalHistorySyncStatesTable createAlias(String alias) {
    return $LocalHistorySyncStatesTable(attachedDatabase, alias);
  }
}

class LocalHistorySyncState extends DataClass
    implements Insertable<LocalHistorySyncState> {
  final String recordId;
  final String stateJson;
  const LocalHistorySyncState({
    required this.recordId,
    required this.stateJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['record_id'] = Variable<String>(recordId);
    map['state_json'] = Variable<String>(stateJson);
    return map;
  }

  LocalHistorySyncStatesCompanion toCompanion(bool nullToAbsent) {
    return LocalHistorySyncStatesCompanion(
      recordId: Value(recordId),
      stateJson: Value(stateJson),
    );
  }

  factory LocalHistorySyncState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalHistorySyncState(
      recordId: serializer.fromJson<String>(json['recordId']),
      stateJson: serializer.fromJson<String>(json['stateJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recordId': serializer.toJson<String>(recordId),
      'stateJson': serializer.toJson<String>(stateJson),
    };
  }

  LocalHistorySyncState copyWith({String? recordId, String? stateJson}) =>
      LocalHistorySyncState(
        recordId: recordId ?? this.recordId,
        stateJson: stateJson ?? this.stateJson,
      );
  LocalHistorySyncState copyWithCompanion(
    LocalHistorySyncStatesCompanion data,
  ) {
    return LocalHistorySyncState(
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      stateJson: data.stateJson.present ? data.stateJson.value : this.stateJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalHistorySyncState(')
          ..write('recordId: $recordId, ')
          ..write('stateJson: $stateJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recordId, stateJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalHistorySyncState &&
          other.recordId == this.recordId &&
          other.stateJson == this.stateJson);
}

class LocalHistorySyncStatesCompanion
    extends UpdateCompanion<LocalHistorySyncState> {
  final Value<String> recordId;
  final Value<String> stateJson;
  final Value<int> rowid;
  const LocalHistorySyncStatesCompanion({
    this.recordId = const Value.absent(),
    this.stateJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalHistorySyncStatesCompanion.insert({
    required String recordId,
    required String stateJson,
    this.rowid = const Value.absent(),
  }) : recordId = Value(recordId),
       stateJson = Value(stateJson);
  static Insertable<LocalHistorySyncState> custom({
    Expression<String>? recordId,
    Expression<String>? stateJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recordId != null) 'record_id': recordId,
      if (stateJson != null) 'state_json': stateJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalHistorySyncStatesCompanion copyWith({
    Value<String>? recordId,
    Value<String>? stateJson,
    Value<int>? rowid,
  }) {
    return LocalHistorySyncStatesCompanion(
      recordId: recordId ?? this.recordId,
      stateJson: stateJson ?? this.stateJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (stateJson.present) {
      map['state_json'] = Variable<String>(stateJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalHistorySyncStatesCompanion(')
          ..write('recordId: $recordId, ')
          ..write('stateJson: $stateJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalAppMetadataTable extends LocalAppMetadata
    with TableInfo<$LocalAppMetadataTable, LocalAppMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAppMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_app_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAppMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalAppMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAppMetadataData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $LocalAppMetadataTable createAlias(String alias) {
    return $LocalAppMetadataTable(attachedDatabase, alias);
  }
}

class LocalAppMetadataData extends DataClass
    implements Insertable<LocalAppMetadataData> {
  final String key;
  final String value;
  const LocalAppMetadataData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalAppMetadataCompanion toCompanion(bool nullToAbsent) {
    return LocalAppMetadataCompanion(key: Value(key), value: Value(value));
  }

  factory LocalAppMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAppMetadataData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  LocalAppMetadataData copyWith({String? key, String? value}) =>
      LocalAppMetadataData(key: key ?? this.key, value: value ?? this.value);
  LocalAppMetadataData copyWithCompanion(LocalAppMetadataCompanion data) {
    return LocalAppMetadataData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAppMetadataData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAppMetadataData &&
          other.key == this.key &&
          other.value == this.value);
}

class LocalAppMetadataCompanion extends UpdateCompanion<LocalAppMetadataData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const LocalAppMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAppMetadataCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<LocalAppMetadataData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAppMetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return LocalAppMetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAppMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalCasesTable localCases = $LocalCasesTable(this);
  late final $LocalCaseSyncStatesTable localCaseSyncStates =
      $LocalCaseSyncStatesTable(this);
  late final $LocalHistoryRecordsTable localHistoryRecords =
      $LocalHistoryRecordsTable(this);
  late final $LocalHistorySyncStatesTable localHistorySyncStates =
      $LocalHistorySyncStatesTable(this);
  late final $LocalAppMetadataTable localAppMetadata = $LocalAppMetadataTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localCases,
    localCaseSyncStates,
    localHistoryRecords,
    localHistorySyncStates,
    localAppMetadata,
  ];
}

typedef $$LocalCasesTableCreateCompanionBuilder = LocalCasesCompanion Function({
  required String id,
  required String profileJson,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocalCasesTableUpdateCompanionBuilder = LocalCasesCompanion Function({
  Value<String> id,
  Value<String> profileJson,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalCasesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCasesTable> {
  $$LocalCasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCasesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCasesTable> {
  $$LocalCasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCasesTable> {
  $$LocalCasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalCasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCasesTable,
          LocalCase,
          $$LocalCasesTableFilterComposer,
          $$LocalCasesTableOrderingComposer,
          $$LocalCasesTableAnnotationComposer,
          $$LocalCasesTableCreateCompanionBuilder,
          $$LocalCasesTableUpdateCompanionBuilder,
          (
            LocalCase,
            BaseReferences<_$AppDatabase, $LocalCasesTable, LocalCase>,
          ),
          LocalCase,
          PrefetchHooks Function()
        > {
  $$LocalCasesTableTableManager(_$AppDatabase db, $LocalCasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCasesCompanion(
                id: id,
                profileJson: profileJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalCasesCompanion.insert(
                id: id,
                profileJson: profileJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCasesTable,
      LocalCase,
      $$LocalCasesTableFilterComposer,
      $$LocalCasesTableOrderingComposer,
      $$LocalCasesTableAnnotationComposer,
      $$LocalCasesTableCreateCompanionBuilder,
      $$LocalCasesTableUpdateCompanionBuilder,
      (LocalCase, BaseReferences<_$AppDatabase, $LocalCasesTable, LocalCase>),
      LocalCase,
      PrefetchHooks Function()
    >;
typedef $$LocalCaseSyncStatesTableCreateCompanionBuilder =
    LocalCaseSyncStatesCompanion Function({
      required String localId,
      Value<String?> serverId,
      Value<String?> pendingDeleteServerId,
      Value<int> rowid,
    });
typedef $$LocalCaseSyncStatesTableUpdateCompanionBuilder =
    LocalCaseSyncStatesCompanion Function({
      Value<String> localId,
      Value<String?> serverId,
      Value<String?> pendingDeleteServerId,
      Value<int> rowid,
    });

class $$LocalCaseSyncStatesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCaseSyncStatesTable> {
  $$LocalCaseSyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pendingDeleteServerId => $composableBuilder(
    column: $table.pendingDeleteServerId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCaseSyncStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCaseSyncStatesTable> {
  $$LocalCaseSyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pendingDeleteServerId => $composableBuilder(
    column: $table.pendingDeleteServerId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCaseSyncStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCaseSyncStatesTable> {
  $$LocalCaseSyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get pendingDeleteServerId => $composableBuilder(
    column: $table.pendingDeleteServerId,
    builder: (column) => column,
  );
}

class $$LocalCaseSyncStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCaseSyncStatesTable,
          LocalCaseSyncState,
          $$LocalCaseSyncStatesTableFilterComposer,
          $$LocalCaseSyncStatesTableOrderingComposer,
          $$LocalCaseSyncStatesTableAnnotationComposer,
          $$LocalCaseSyncStatesTableCreateCompanionBuilder,
          $$LocalCaseSyncStatesTableUpdateCompanionBuilder,
          (
            LocalCaseSyncState,
            BaseReferences<
              _$AppDatabase,
              $LocalCaseSyncStatesTable,
              LocalCaseSyncState
            >,
          ),
          LocalCaseSyncState,
          PrefetchHooks Function()
        > {
  $$LocalCaseSyncStatesTableTableManager(
    _$AppDatabase db,
    $LocalCaseSyncStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCaseSyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCaseSyncStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalCaseSyncStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String?> pendingDeleteServerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCaseSyncStatesCompanion(
                localId: localId,
                serverId: serverId,
                pendingDeleteServerId: pendingDeleteServerId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String?> serverId = const Value.absent(),
                Value<String?> pendingDeleteServerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCaseSyncStatesCompanion.insert(
                localId: localId,
                serverId: serverId,
                pendingDeleteServerId: pendingDeleteServerId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCaseSyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCaseSyncStatesTable,
      LocalCaseSyncState,
      $$LocalCaseSyncStatesTableFilterComposer,
      $$LocalCaseSyncStatesTableOrderingComposer,
      $$LocalCaseSyncStatesTableAnnotationComposer,
      $$LocalCaseSyncStatesTableCreateCompanionBuilder,
      $$LocalCaseSyncStatesTableUpdateCompanionBuilder,
      (
        LocalCaseSyncState,
        BaseReferences<
          _$AppDatabase,
          $LocalCaseSyncStatesTable,
          LocalCaseSyncState
        >,
      ),
      LocalCaseSyncState,
      PrefetchHooks Function()
    >;
typedef $$LocalHistoryRecordsTableCreateCompanionBuilder =
    LocalHistoryRecordsCompanion Function({
      required String id,
      required String recordJson,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalHistoryRecordsTableUpdateCompanionBuilder =
    LocalHistoryRecordsCompanion Function({
      Value<String> id,
      Value<String> recordJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalHistoryRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalHistoryRecordsTable> {
  $$LocalHistoryRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordJson => $composableBuilder(
    column: $table.recordJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalHistoryRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalHistoryRecordsTable> {
  $$LocalHistoryRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordJson => $composableBuilder(
    column: $table.recordJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalHistoryRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalHistoryRecordsTable> {
  $$LocalHistoryRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recordJson => $composableBuilder(
    column: $table.recordJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalHistoryRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalHistoryRecordsTable,
          LocalHistoryRecord,
          $$LocalHistoryRecordsTableFilterComposer,
          $$LocalHistoryRecordsTableOrderingComposer,
          $$LocalHistoryRecordsTableAnnotationComposer,
          $$LocalHistoryRecordsTableCreateCompanionBuilder,
          $$LocalHistoryRecordsTableUpdateCompanionBuilder,
          (
            LocalHistoryRecord,
            BaseReferences<
              _$AppDatabase,
              $LocalHistoryRecordsTable,
              LocalHistoryRecord
            >,
          ),
          LocalHistoryRecord,
          PrefetchHooks Function()
        > {
  $$LocalHistoryRecordsTableTableManager(
    _$AppDatabase db,
    $LocalHistoryRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalHistoryRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalHistoryRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalHistoryRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> recordJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalHistoryRecordsCompanion(
                id: id,
                recordJson: recordJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String recordJson,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalHistoryRecordsCompanion.insert(
                id: id,
                recordJson: recordJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalHistoryRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalHistoryRecordsTable,
      LocalHistoryRecord,
      $$LocalHistoryRecordsTableFilterComposer,
      $$LocalHistoryRecordsTableOrderingComposer,
      $$LocalHistoryRecordsTableAnnotationComposer,
      $$LocalHistoryRecordsTableCreateCompanionBuilder,
      $$LocalHistoryRecordsTableUpdateCompanionBuilder,
      (
        LocalHistoryRecord,
        BaseReferences<
          _$AppDatabase,
          $LocalHistoryRecordsTable,
          LocalHistoryRecord
        >,
      ),
      LocalHistoryRecord,
      PrefetchHooks Function()
    >;
typedef $$LocalHistorySyncStatesTableCreateCompanionBuilder =
    LocalHistorySyncStatesCompanion Function({
      required String recordId,
      required String stateJson,
      Value<int> rowid,
    });
typedef $$LocalHistorySyncStatesTableUpdateCompanionBuilder =
    LocalHistorySyncStatesCompanion Function({
      Value<String> recordId,
      Value<String> stateJson,
      Value<int> rowid,
    });

class $$LocalHistorySyncStatesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalHistorySyncStatesTable> {
  $$LocalHistorySyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalHistorySyncStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalHistorySyncStatesTable> {
  $$LocalHistorySyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalHistorySyncStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalHistorySyncStatesTable> {
  $$LocalHistorySyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get stateJson =>
      $composableBuilder(column: $table.stateJson, builder: (column) => column);
}

class $$LocalHistorySyncStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalHistorySyncStatesTable,
          LocalHistorySyncState,
          $$LocalHistorySyncStatesTableFilterComposer,
          $$LocalHistorySyncStatesTableOrderingComposer,
          $$LocalHistorySyncStatesTableAnnotationComposer,
          $$LocalHistorySyncStatesTableCreateCompanionBuilder,
          $$LocalHistorySyncStatesTableUpdateCompanionBuilder,
          (
            LocalHistorySyncState,
            BaseReferences<
              _$AppDatabase,
              $LocalHistorySyncStatesTable,
              LocalHistorySyncState
            >,
          ),
          LocalHistorySyncState,
          PrefetchHooks Function()
        > {
  $$LocalHistorySyncStatesTableTableManager(
    _$AppDatabase db,
    $LocalHistorySyncStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalHistorySyncStatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalHistorySyncStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalHistorySyncStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> recordId = const Value.absent(),
                Value<String> stateJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalHistorySyncStatesCompanion(
                recordId: recordId,
                stateJson: stateJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recordId,
                required String stateJson,
                Value<int> rowid = const Value.absent(),
              }) => LocalHistorySyncStatesCompanion.insert(
                recordId: recordId,
                stateJson: stateJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalHistorySyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalHistorySyncStatesTable,
      LocalHistorySyncState,
      $$LocalHistorySyncStatesTableFilterComposer,
      $$LocalHistorySyncStatesTableOrderingComposer,
      $$LocalHistorySyncStatesTableAnnotationComposer,
      $$LocalHistorySyncStatesTableCreateCompanionBuilder,
      $$LocalHistorySyncStatesTableUpdateCompanionBuilder,
      (
        LocalHistorySyncState,
        BaseReferences<
          _$AppDatabase,
          $LocalHistorySyncStatesTable,
          LocalHistorySyncState
        >,
      ),
      LocalHistorySyncState,
      PrefetchHooks Function()
    >;
typedef $$LocalAppMetadataTableCreateCompanionBuilder =
    LocalAppMetadataCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$LocalAppMetadataTableUpdateCompanionBuilder =
    LocalAppMetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$LocalAppMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $LocalAppMetadataTable> {
  $$LocalAppMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAppMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalAppMetadataTable> {
  $$LocalAppMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAppMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalAppMetadataTable> {
  $$LocalAppMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$LocalAppMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalAppMetadataTable,
          LocalAppMetadataData,
          $$LocalAppMetadataTableFilterComposer,
          $$LocalAppMetadataTableOrderingComposer,
          $$LocalAppMetadataTableAnnotationComposer,
          $$LocalAppMetadataTableCreateCompanionBuilder,
          $$LocalAppMetadataTableUpdateCompanionBuilder,
          (
            LocalAppMetadataData,
            BaseReferences<
              _$AppDatabase,
              $LocalAppMetadataTable,
              LocalAppMetadataData
            >,
          ),
          LocalAppMetadataData,
          PrefetchHooks Function()
        > {
  $$LocalAppMetadataTableTableManager(
    _$AppDatabase db,
    $LocalAppMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAppMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAppMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAppMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => LocalAppMetadataCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => LocalAppMetadataCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAppMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalAppMetadataTable,
      LocalAppMetadataData,
      $$LocalAppMetadataTableFilterComposer,
      $$LocalAppMetadataTableOrderingComposer,
      $$LocalAppMetadataTableAnnotationComposer,
      $$LocalAppMetadataTableCreateCompanionBuilder,
      $$LocalAppMetadataTableUpdateCompanionBuilder,
      (
        LocalAppMetadataData,
        BaseReferences<
          _$AppDatabase,
          $LocalAppMetadataTable,
          LocalAppMetadataData
        >,
      ),
      LocalAppMetadataData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalCasesTableTableManager get localCases =>
      $$LocalCasesTableTableManager(_db, _db.localCases);
  $$LocalCaseSyncStatesTableTableManager get localCaseSyncStates =>
      $$LocalCaseSyncStatesTableTableManager(_db, _db.localCaseSyncStates);
  $$LocalHistoryRecordsTableTableManager get localHistoryRecords =>
      $$LocalHistoryRecordsTableTableManager(_db, _db.localHistoryRecords);
  $$LocalHistorySyncStatesTableTableManager get localHistorySyncStates =>
      $$LocalHistorySyncStatesTableTableManager(
        _db,
        _db.localHistorySyncStates,
      );
  $$LocalAppMetadataTableTableManager get localAppMetadata =>
      $$LocalAppMetadataTableTableManager(_db, _db.localAppMetadata);
}
