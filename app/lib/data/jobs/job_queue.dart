import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/ids.dart';
import '../db/app_database.dart';
import '../db/tables.dart';

/// Persistent list of pending network work. A job is identified by
/// (kind, subject): enqueueing it again just reschedules it.
class JobQueue {
  JobQueue(this._db, this._clock, this._ids);

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  Future<void> enqueue(JobKind kind, String subjectId, {DateTime? notBefore}) {
    final now = _clock.now();
    final when = (notBefore ?? now).toUtc();
    return _db.transaction(() async {
      final existing = await _find(kind, subjectId);
      if (existing == null) {
        await _db
            .into(_db.jobs)
            .insert(
              JobsCompanion.insert(
                id: _ids.newId(),
                kind: kind,
                subjectId: subjectId,
                nextAttemptAt: when,
                createdAt: now,
                updatedAt: now,
              ),
            );
      } else {
        // New information (e.g. the trip's times changed): start over.
        await (_db.update(
          _db.jobs,
        )..where((j) => j.id.equals(existing.id))).write(
          JobsCompanion(
            attempts: const Value(0),
            nextAttemptAt: Value(when),
            lastError: const Value(null),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  Future<JobRow?> _find(JobKind kind, String subjectId) =>
      (_db.select(_db.jobs)..where(
            (j) => j.kind.equalsValue(kind) & j.subjectId.equals(subjectId),
          ))
          .getSingleOrNull();

  Future<JobRow?> find(JobKind kind, String subjectId) =>
      _find(kind, subjectId);

  /// Jobs whose time has come, oldest first.
  Future<List<JobRow>> due() =>
      (_db.select(_db.jobs)
            ..where((j) => j.nextAttemptAt.isSmallerOrEqualValue(_clock.now()))
            ..orderBy([(j) => OrderingTerm.asc(j.nextAttemptAt)]))
          .get();

  Future<List<JobRow>> all() => _db.select(_db.jobs).get();

  Future<void> complete(String id) =>
      (_db.delete(_db.jobs)..where((j) => j.id.equals(id))).go();

  Future<void> retryAt(String id, DateTime when, {String? error}) async {
    final job = await (_db.select(
      _db.jobs,
    )..where((j) => j.id.equals(id))).getSingleOrNull();
    if (job == null) return;
    await (_db.update(_db.jobs)..where((j) => j.id.equals(id))).write(
      JobsCompanion(
        attempts: Value(job.attempts + 1),
        nextAttemptAt: Value(when.toUtc()),
        lastError: Value(error),
        updatedAt: Value(_clock.now()),
      ),
    );
  }

  /// Next run of a recurring job: attempts start over.
  Future<void> reschedule(String id, DateTime when) =>
      (_db.update(_db.jobs)..where((j) => j.id.equals(id))).write(
        JobsCompanion(
          attempts: const Value(0),
          nextAttemptAt: Value(when.toUtc()),
          lastError: const Value(null),
          updatedAt: Value(_clock.now()),
        ),
      );

  Future<void> cancel(JobKind kind, String subjectId) =>
      (_db.delete(_db.jobs)..where(
            (j) => j.kind.equalsValue(kind) & j.subjectId.equals(subjectId),
          ))
          .go();
}
