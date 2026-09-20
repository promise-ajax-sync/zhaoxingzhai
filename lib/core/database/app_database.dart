import 'package:drift/drift.dart';
import 'package:zhaoxingzhai/core/database/app_database_connection.dart';

part 'app_database.g.dart';

class LocalCases extends Table {
  TextColumn get id => text()();
  TextColumn get profileJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalCaseSyncStates extends Table {
  TextColumn get localId => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get pendingDeleteServerId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class LocalHistoryRecords extends Table {
  TextColumn get id => text()();
  TextColumn get recordJson => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalHistorySyncStates extends Table {
  TextColumn get recordId => text()();
  TextColumn get stateJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {recordId};
}

class LocalAppMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    LocalCases,
    LocalCaseSyncStates,
    LocalHistoryRecords,
    LocalHistorySyncStates,
    LocalAppMetadata,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openAppDatabase());

  static final AppDatabase shared = AppDatabase();

  @override
  int get schemaVersion => 1;

  Future<List<LocalCase>> loadCases() => (select(
    localCases,
  )..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])).get();

  Future<void> replaceCases(Iterable<LocalCasesCompanion> rows) async {
    await transaction(() async {
      await delete(localCases).go();
      await batch((batch) => batch.insertAll(localCases, rows));
    });
  }

  Future<List<LocalCaseSyncState>> loadCaseSyncStates() =>
      select(localCaseSyncStates).get();

  Future<void> replaceCaseSyncStates(
    Iterable<LocalCaseSyncStatesCompanion> rows,
  ) async {
    await transaction(() async {
      await delete(localCaseSyncStates).go();
      await batch((batch) => batch.insertAll(localCaseSyncStates, rows));
    });
  }

  Future<List<LocalHistoryRecord>> loadHistoryRecords() => (select(
    localHistoryRecords,
  )..orderBy([(row) => OrderingTerm.desc(row.createdAt)])).get();

  Future<void> replaceHistoryRecords(
    Iterable<LocalHistoryRecordsCompanion> rows,
  ) async {
    await transaction(() async {
      await delete(localHistoryRecords).go();
      await batch((batch) => batch.insertAll(localHistoryRecords, rows));
    });
  }

  Future<List<LocalHistorySyncState>> loadHistorySyncStates() =>
      select(localHistorySyncStates).get();

  Future<void> replaceHistorySyncStates(
    Iterable<LocalHistorySyncStatesCompanion> rows,
  ) async {
    await transaction(() async {
      await delete(localHistorySyncStates).go();
      await batch((batch) => batch.insertAll(localHistorySyncStates, rows));
    });
  }

  Future<String?> metadataValue(String key) async {
    final row = await (select(
      localAppMetadata,
    )..where((item) => item.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setMetadataValue(String key, String value) =>
      into(localAppMetadata).insertOnConflictUpdate(
        LocalAppMetadataCompanion.insert(key: key, value: value),
      );
}
