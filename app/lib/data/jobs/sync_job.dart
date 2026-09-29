import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

import '../../core/clock.dart';
import '../account/account_repository.dart';
import '../db/app_database.dart';
import '../db/tables.dart';
import '../remote/piscatio_api.dart';
import '../repositories/settings_repository.dart';
import '../sync/sync_service.dart';
import 'job_queue.dart';
import 'job_runner.dart';

typedef ApiFactory = PiscatioApi Function(String base, String? token);

/// The only subject of the sync job: there is one account per device.
const syncSubject = 'account';

/// Every 15 minutes while signed in (and whenever asked): push what changed
/// here, pull what changed elsewhere, queue photo transfers.
class SyncJobHandler implements JobHandler {
  SyncJobHandler({
    required this._account,
    required this._sync,
    required this._settings,
    required this._queue,
    required this._api,
    required this._clock,
    required this._onNewTrip,
    required this._onSecretChanged,
    required this._kick,
  });

  final AccountRepository _account;
  final SyncService _sync;
  final SettingsRepository _settings;
  final JobQueue _queue;
  final ApiFactory _api;
  final Clock _clock;
  final Future<void> Function(String tripId) _onNewTrip;
  final void Function() _onSecretChanged;
  final void Function() _kick;

  static const every = Duration(minutes: 15);

  @override
  JobKind get kind => JobKind.sync;

  @override
  Future<JobOutcome> run(JobRow job) async {
    final account = await _account.read();
    final token = await _account.token();
    if (account == null || token == null) return const JobDone();
    final api = _api(account.server, token);
    try {
      await _shareSecret(api);
      var transfers = false;
      for (var round = 0; round < 50; round++) {
        final (changes, rows) = await _sync.pending();
        if (rows.isEmpty) break;
        final result = await api.push(changes);
        await _sync.markPushed(rows, result);
        for (final id in result.needsFile) {
          await _queue.enqueue(JobKind.photoUpload, id);
          transfers = true;
        }
      }
      var cursor = await _account.cursor();
      for (var round = 0; round < 200; round++) {
        final page = await api.pull(cursor);
        final outcome = await _sync.apply(page);
        for (final id in outcome.missingPhotos) {
          await _queue.enqueue(JobKind.photoDownload, id);
          transfers = true;
        }
        for (final id in outcome.newTrips) {
          await _onNewTrip(id);
        }
        cursor = page.cursor;
        await _account.setCursor(cursor);
        if (!page.more) break;
      }
      await _account.setLastSync(_clock.now());
      if (transfers) _kick();
      return JobReschedule(_clock.now().add(every));
    } on ApiSignedOut {
      await _account.signOut();
      await _sync.forgetServer();
      return const JobDone();
    }
  }

  /// All the person's devices hide the same spot the same way: the first
  /// one's secret becomes the account's.
  Future<void> _shareSecret(PiscatioApi api) async {
    if (await _account.secretShared()) return;
    final local = await _settings.privacySecret();
    final shared = base64Decode(await api.privacySecret(base64Encode(local)));
    if (!const ListEquality<int>().equals(shared, local)) {
      await _settings.setPrivacySecret(shared);
      _onSecretChanged();
    }
    await _account.setSecretShared();
  }

  @override
  Future<void> giveUp(JobRow job) async {}
}

/// Sends one photo's image to the server (the backup).
class PhotoUploadHandler implements JobHandler {
  PhotoUploadHandler({
    required this._db,
    required this._account,
    required this._api,
    required this._root,
    required this._clock,
  });

  final AppDatabase _db;
  final AccountRepository _account;
  final ApiFactory _api;
  final Future<Directory> Function() _root;
  final Clock _clock;

  @override
  JobKind get kind => JobKind.photoUpload;

  @override
  Future<JobOutcome> run(JobRow job) async {
    final account = await _account.read();
    final token = await _account.token();
    if (account == null || token == null) return const JobDone();
    final photo = await (_db.select(
      _db.catchPhotos,
    )..where((r) => r.id.equals(job.subjectId))).getSingleOrNull();
    if (photo == null || photo.deletedAt != null) return const JobDone();
    final file = File(p.join((await _root()).path, photo.relativePath));
    if (!file.existsSync()) return const JobDone();
    try {
      await _api(
        account.server,
        token,
      ).uploadPhoto(photo.id, await file.readAsBytes());
    } on ApiSignedOut {
      return const JobDone();
    } on ApiRejected catch (e) {
      // The row is not on the server yet: the next sync pushes it.
      if (e.status == 404) {
        return JobRetryAt(_clock.now().add(SyncJobHandler.every));
      }
      return const JobDone();
    }
    return const JobDone();
  }

  @override
  Future<void> giveUp(JobRow job) async {}
}

/// Brings a photo's image from the server (a new phone, another device).
class PhotoDownloadHandler implements JobHandler {
  PhotoDownloadHandler({
    required this._db,
    required this._account,
    required this._api,
    required this._root,
  });

  final AppDatabase _db;
  final AccountRepository _account;
  final ApiFactory _api;
  final Future<Directory> Function() _root;

  @override
  JobKind get kind => JobKind.photoDownload;

  @override
  Future<JobOutcome> run(JobRow job) async {
    final account = await _account.read();
    final token = await _account.token();
    if (account == null || token == null) return const JobDone();
    final photo = await (_db.select(
      _db.catchPhotos,
    )..where((r) => r.id.equals(job.subjectId))).getSingleOrNull();
    if (photo == null || photo.deletedAt != null) return const JobDone();
    final file = File(p.join((await _root()).path, photo.relativePath));
    if (file.existsSync()) return const JobDone();
    try {
      final bytes = await _api(account.server, token).downloadPhoto(photo.id);
      await file.parent.create(recursive: true);
      final part = File('${file.path}.part');
      await part.writeAsBytes(bytes, flush: true);
      await part.rename(file.path);
    } on ApiSignedOut {
      return const JobDone();
    } on ApiRejected {
      return const JobDone();
    }
    return const JobDone();
  }

  @override
  Future<void> giveUp(JobRow job) async {}
}
