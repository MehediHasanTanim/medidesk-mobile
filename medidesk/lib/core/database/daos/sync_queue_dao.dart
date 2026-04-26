import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<List<SyncQueueEntry>> getPending({int limit = 20}) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return (select(syncQueue)
          ..where(
            (t) =>
                (t.status.equals('PENDING') | t.status.equals('FAILED')) &
                t.nextRetryAt.isSmallerOrEqualValue(nowMs),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<void> enqueue(SyncQueueCompanion entry) =>
      into(syncQueue).insert(entry);

  Future<void> markProcessing(String id) =>
      (update(syncQueue)..where((t) => t.id.equals(id))).write(
        const SyncQueueCompanion(status: Value('PROCESSING')),
      );

  Future<void> markSynced(String id) =>
      (update(syncQueue)..where((t) => t.id.equals(id))).write(
        const SyncQueueCompanion(status: Value('SYNCED')),
      );

  Future<void> markFailed(
    String id,
    String errorMessage,
    int nextRetryAt, {
    required int retryCount,
  }) =>
      (update(syncQueue)..where((t) => t.id.equals(id))).write(
        SyncQueueCompanion(
          status: const Value('FAILED'),
          errorMessage: Value(errorMessage),
          nextRetryAt: Value(nextRetryAt),
          retryCount: Value(retryCount),
        ),
      );

  /// Reactive count of PENDING + FAILED entries — drives the badge in the UI.
  Stream<int> watchPendingCount() {
    return customSelect(
      'SELECT COUNT(*) AS cnt FROM sync_queue '
      "WHERE status = 'PENDING' OR status = 'FAILED'",
      readsFrom: {syncQueue},
    ).map((row) => row.read<int>('cnt')).watchSingle();
  }

  /// Purge SYNCED entries older than 7 days to keep the table lean.
  Future<void> deleteOldSynced() {
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    return (delete(syncQueue)
          ..where(
            (t) =>
                t.status.equals('SYNCED') &
                t.createdAt.isSmallerOrEqualValue(cutoff),
          ))
        .go();
  }
}
