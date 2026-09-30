import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/clock.dart';
import '../../core/ids.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/social.dart';
import '../account/account_repository.dart';
import '../db/app_database.dart';
import '../jobs/sync_job.dart';
import '../remote/piscatio_api.dart';

/// The community: the server for everything other people made (feed,
/// profiles), and an outbox for what the person publishes, so a card
/// published offline goes up by itself later.
class SocialRepository {
  SocialRepository({
    required this._db,
    required this._account,
    required this._api,
    required this._clock,
    required this._ids,
    required this._root,
  });

  final AppDatabase _db;
  final AccountRepository _account;
  final ApiFactory _api;
  final Clock _clock;
  final IdGenerator _ids;
  final Future<Directory> Function() _root;

  /// Where queued card images wait, inside the app's documents.
  static const folder = 'outbox';

  /// The server as the signed-in person. Throws [ApiSignedOut] without an
  /// account.
  Future<PiscatioApi> api() async {
    final account = await _account.read();
    final token = await _account.token();
    if (account == null || token == null) throw const ApiSignedOut();
    return _api(account.server, token);
  }

  Stream<List<OutboxPost>> watchOutbox() =>
      (_db.select(_db.outboxPosts)
            ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
          .watch()
          .map((rows) => [for (final r in rows) _post(r)]);

  static OutboxPost _post(OutboxPostRow r) => OutboxPost(
    id: r.id,
    kind: PostKind.of(r.kind),
    audience: r.audience,
    imagePath: r.imagePath,
    createdAt: r.createdAt,
    caption: r.caption,
    error: r.error,
  );

  /// Keeps the card image and its facts until the upload job sends them.
  /// Returns the post's id.
  Future<String> queue({
    required Uint8List png,
    required int width,
    required int height,
    required PostKind kind,
    required CardAudience audience,
    String? tripId,
    String? catchId,
    String? speciesId,
    String? venueId,
    String? caption,
  }) async {
    final id = _ids.newId();
    final relative = p.join(folder, '$id.png');
    final file = File(p.join((await _root()).path, relative));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png, flush: true);
    final now = _clock.now();
    final text = caption?.trim();
    await _db
        .into(_db.outboxPosts)
        .insert(
          OutboxPostsCompanion.insert(
            id: id,
            kind: kind.wire,
            audience: audience,
            tripId: Value(tripId),
            catchId: Value(catchId),
            speciesId: Value(speciesId),
            venueId: Value(venueId),
            caption: Value(text == null || text.isEmpty ? null : text),
            imagePath: relative,
            width: width,
            height: height,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<OutboxPostRow?> _row(String id) => (_db.select(
    _db.outboxPosts,
  )..where((o) => o.id.equals(id))).getSingleOrNull();

  /// Sends one queued post: its facts, then its image if the server asks.
  /// Throws [ApiUnavailable] to be tried again later.
  Future<void> upload(String id) async {
    final row = await _row(id);
    if (row == null || row.error != null) return;
    final file = File(p.join((await _root()).path, row.imagePath));
    if (!file.existsSync()) {
      await discard(id);
      return;
    }
    try {
      final server = await api();
      final needsImage = await server.putPost(id, {
        'kind': row.kind,
        'audience': audienceWire(row.audience),
        'trip_id': row.tripId,
        'catch_id': row.catchId,
        'species_id': row.speciesId,
        'venue_id': row.venueId,
        'caption': row.caption,
        'width': row.width,
        'height': row.height,
        'created_at': row.createdAt.toUtc().toIso8601String(),
      });
      if (needsImage) {
        await server.uploadPostImage(id, await file.readAsBytes());
      }
    } on ApiRejected catch (e) {
      await fail(id, e.code ?? 'rejected_${e.status}');
      return;
    } on ApiSignedOut {
      await fail(id, 'signed_out');
      return;
    }
    await discard(id);
  }

  /// Keeps the post, marked with why it did not go up.
  Future<void> fail(String id, String reason) =>
      (_db.update(_db.outboxPosts)..where((o) => o.id.equals(id))).write(
        OutboxPostsCompanion(
          error: Value(reason),
          updatedAt: Value(_clock.now()),
        ),
      );

  /// Clears the failure so the job tries again.
  Future<void> retry(String id) =>
      (_db.update(_db.outboxPosts)..where((o) => o.id.equals(id))).write(
        OutboxPostsCompanion(
          error: const Value(null),
          updatedAt: Value(_clock.now()),
        ),
      );

  /// Removes the post and its image (sent, or given up by the person).
  Future<void> discard(String id) async {
    final row = await _row(id);
    if (row == null) return;
    final file = File(p.join((await _root()).path, row.imagePath));
    if (file.existsSync()) await file.delete();
    await (_db.delete(_db.outboxPosts)..where((o) => o.id.equals(id))).go();
  }
}
