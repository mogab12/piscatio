import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:piscatio/core/clock.dart';
import 'package:piscatio/core/ids.dart';
import 'package:piscatio/data/account/account_repository.dart';
import 'package:piscatio/data/db/app_database.dart';
import 'package:piscatio/data/db/tables.dart';
import 'package:piscatio/data/jobs/job_queue.dart';
import 'package:piscatio/data/jobs/job_runner.dart';
import 'package:piscatio/data/jobs/post_upload_job.dart';
import 'package:piscatio/data/remote/piscatio_api.dart';
import 'package:piscatio/data/repositories/settings_repository.dart';
import 'package:piscatio/data/social/social_repository.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/social.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_db.dart';

void main() {
  late FakeServer server;
  late AppDatabase db;
  late Directory root;
  late AccountRepository account;
  late SocialRepository social;
  late JobQueue queue;
  late JobRunner runner;
  final clock = FixedClock(DateTime.utc(2026, 9, 12, 12));
  final png = Uint8List.fromList(List.generate(64, (i) => i));

  setUp(() async {
    server = FakeServer()..profile = FakeServer.person('ana');
    db = await newSeededDatabase();
    root = Directory.systemTemp.createTempSync('piscatio_social');
    account = AccountRepository(db, SettingsRepository(db), FakeTokenStore());
    await account.signedIn(
      const ApiSession(token: FakeServer.token, email: FakeServer.email),
    );
    social = SocialRepository(
      db: db,
      account: account,
      api: (base, token) =>
          PiscatioApi(server.client(), base: base, token: token),
      clock: clock,
      ids: const UuidV7Generator(),
      root: () async => root,
    );
    queue = JobQueue(db, clock, const UuidV7Generator());
    runner = JobRunner(queue, [PostUploadHandler(social)], clock);
  });

  tearDown(() async {
    await db.close();
    root.deleteSync(recursive: true);
  });

  Future<String> queuePost() => social.queue(
    png: png,
    width: 1080,
    height: 1920,
    kind: PostKind.catchCard,
    audience: CardAudience.friends,
    tripId: 'trip-1',
    catchId: 'catch-1',
    speciesId: 'hoplias-malabaricus',
    caption: '  Traíra de 2 kg ',
  );

  Future<List<OutboxPost>> outbox() => social.watchOutbox().first;

  Future<void> upload(String id) async {
    await queue.enqueue(JobKind.postUpload, id);
    await runner.runDue();
  }

  test('a queued card goes up with its facts, then leaves the phone', () async {
    final id = await queuePost();
    final waiting = (await outbox()).single;
    expect(waiting.caption, 'Traíra de 2 kg');
    final file = File(p.join(root.path, waiting.imagePath));
    expect(file.existsSync(), isTrue);

    await upload(id);
    expect(server.posts[id], containsPair('audience', 'friends'));
    expect(server.posts[id], containsPair('kind', 'catch'));
    expect(server.posts[id], containsPair('species_id', 'hoplias-malabaricus'));
    expect(server.posts[id], containsPair('caption', 'Traíra de 2 kg'));
    expect(server.posts[id], containsPair('width', 1080));
    // No coordinates in what goes up, ever.
    expect(server.posts[id]!.keys, isNot(contains('latitude')));
    expect(server.postImages[id], png);
    expect(await outbox(), isEmpty);
    expect(file.existsSync(), isFalse);
    expect(await queue.all(), isEmpty);
  });

  test('offline: kept and tried again later', () async {
    final id = await queuePost();
    server.down = true;
    await upload(id);
    expect((await outbox()).single.error, isNull);
    final job = (await queue.all()).single;
    expect(job.attempts, 1);
    expect(job.nextAttemptAt.isAfter(clock.now()), isTrue);
  });

  test('refused (no profile): kept with the reason until retried', () async {
    final id = await queuePost();
    server.profile = null;
    await upload(id);
    expect((await outbox()).single.error, 'profile_required');
    expect(await queue.all(), isEmpty);

    server.profile = FakeServer.person('ana');
    await social.retry(id);
    await upload(id);
    expect(server.postImages, contains(id));
    expect(await outbox(), isEmpty);
  });

  test('discarding removes the card and its image', () async {
    final id = await queuePost();
    final path = (await outbox()).single.imagePath;
    await social.discard(id);
    expect(await outbox(), isEmpty);
    expect(File(p.join(root.path, path)).existsSync(), isFalse);
  });
}
