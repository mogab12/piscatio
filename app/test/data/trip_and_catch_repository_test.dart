import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/data/db/app_database.dart';
import 'package:piscatio/data/repositories/catch_repository.dart';
import 'package:piscatio/data/repositories/trip_repository.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/domain/services/moon.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late TestDeps deps;
  late TripRepository trips;
  late CatchRepository catches;

  setUp(() async {
    db = await newSeededDatabase();
    deps = TestDeps(db);
    trips = TripRepository(db, deps.clock, deps.ids);
    catches = CatchRepository(db, deps.clock, deps.ids);
  });
  tearDown(() => db.close());

  Future<String> startTrip() async => (await trips.startTrip(
    timezone: 'America/Sao_Paulo',
    privacy: PrivacyLevel.private,
  )).id;

  group('TripRepository', () {
    test('starting a trip stores UTC time, privacy and moon phase', () async {
      final trip = await trips.startTrip(
        timezone: 'America/Cuiaba',
        privacy: PrivacyLevel.approximate,
        location: const GeoPoint(-16.5, -56.4),
        accuracyMeters: 8,
      );
      expect(trip.startedAt, deps.clock.now());
      expect(trip.startedAt.isUtc, isTrue);
      expect(trip.isActive, isTrue);
      expect(trip.privacyLevel, PrivacyLevel.approximate);
      expect(trip.moonPhase, moonAt(deps.clock.now()).phase);
      expect(trip.location, const GeoPoint(-16.5, -56.4));
      expect(await trips.activeTrip(), trip);
    });

    test('only one trip can be active', () async {
      await startTrip();
      expect(startTrip, throwsStateError);
    });

    test('finishing sets ended_at and clears the active trip', () async {
      final id = await startTrip();
      deps.clock.advance(const Duration(hours: 3, minutes: 20));
      await trips.finishTrip(id);
      final trip = await trips.watchTrip(id).first;
      expect(trip!.isActive, isFalse);
      expect(
        trip.duration(deps.clock.now()),
        const Duration(hours: 3, minutes: 20),
      );
      expect(trip.updatedAt, deps.clock.now());
      expect(await trips.activeTrip(), isNull);
    });

    test('past trips are validated and computed at their own date', () async {
      final start = DateTime.utc(2024, 1, 25, 15);
      final trip = await trips.createPastTrip(
        startedAt: start,
        endedAt: start.add(const Duration(hours: 5)),
        timezone: 'America/Sao_Paulo',
        privacy: PrivacyLevel.exact,
        locationName: 'Represa de Furnas',
      );
      expect(trip.isRetroactive, isTrue);
      expect(trip.moonPhase, MoonPhase.fullMoon);
      expect(
        () => trips.createPastTrip(
          startedAt: start,
          endedAt: start,
          timezone: 'UTC',
          privacy: PrivacyLevel.private,
        ),
        throwsArgumentError,
      );
    });

    test('editing the start time recomputes the moon', () async {
      final id = await startTrip();
      await trips.finishTrip(id);
      final trip = (await trips.watchTrip(id).first)!;
      await trips.updateTrip(
        trip.copyWith(
          startedAt: DateTime.utc(2024, 1, 11, 12),
          endedAt: DateTime.utc(2024, 1, 11, 18),
          notes: 'Água turva',
        ),
      );
      final edited = (await trips.watchTrip(id).first)!;
      expect(edited.moonPhase, MoonPhase.newMoon);
      expect(edited.notes, 'Água turva');
    });

    test('overviews aggregate catches and ignore deleted ones', () async {
      final id = await startTrip();
      await catches.addCatch(tripId: id, speciesId: 'hoplias-malabaricus');
      final big = await catches.addCatch(
        tripId: id,
        speciesId: 'salminus-brasiliensis',
        photo: const StoredPhoto(
          relativePath: 'photos/a.jpg',
          width: 1,
          height: 1,
        ),
      );
      await catches.updateDetails(
        big.id,
        const CatchDetails(
          speciesId: 'salminus-brasiliensis',
          weightGrams: 4200,
        ),
      );
      final gone = await catches.addCatch(
        tripId: id,
        speciesId: 'cyprinus-carpio',
      );
      await catches.deleteCatch(gone.id);

      final overview = (await trips.watchOverviews().first).single;
      expect(overview.catchCount, 2);
      expect(overview.speciesCount, 2);
      expect(overview.maxWeightGrams, 4200);
      expect(overview.coverPhotoPath, 'photos/a.jpg');
    });

    test('overviews list most recent first and honor the limit', () async {
      for (var i = 0; i < 3; i++) {
        final id = await startTrip();
        deps.clock.advance(const Duration(hours: 1));
        await trips.finishTrip(id);
        deps.clock.advance(const Duration(days: 1));
      }
      final all = await trips.watchOverviews().first;
      expect(all, hasLength(3));
      expect(all.first.trip.startedAt.isAfter(all.last.trip.startedAt), isTrue);
      expect(await trips.watchOverviews(limit: 2).first, hasLength(2));
    });

    test('deleting a trip soft-deletes its catches and photos', () async {
      final id = await startTrip();
      final c = await catches.addCatch(
        tripId: id,
        photo: const StoredPhoto(
          relativePath: 'photos/b.jpg',
          width: 1,
          height: 1,
        ),
      );
      await trips.deleteTrip(id);
      expect(await trips.watchTrip(id).first, isNull);
      expect(await catches.watchCatch(c.id).first, isNull);
      expect(await trips.watchOverviews().first, isEmpty);

      final tombstone = await db.select(db.trips).getSingle();
      expect(tombstone.deletedAt, isNotNull);
      final photo = await db.select(db.catchPhotos).getSingle();
      expect(photo.deletedAt, isNotNull);
    });
  });

  group('CatchRepository', () {
    test('quick capture stores species, time and photo', () async {
      final tripId = await startTrip();
      deps.clock.advance(const Duration(minutes: 42));
      final c = await catches.addCatch(
        tripId: tripId,
        speciesId: 'cichla-kelberi',
        photo: StoredPhoto(
          relativePath: 'photos/c.jpg',
          width: 1600,
          height: 1200,
          takenAt: DateTime.utc(2026, 9, 12, 6, 41),
        ),
      );
      expect(c.speciesId, 'cichla-kelberi');
      expect(c.caughtAt, deps.clock.now());
      expect(c.released, isNull);
      expect(c.coverPhoto!.relativePath, 'photos/c.jpg');
      expect(c.coverPhoto!.takenAt, DateTime.utc(2026, 9, 12, 6, 41));
    });

    test('catches without species or photo are allowed', () async {
      final c = await catches.addCatch(tripId: await startTrip());
      expect(c.speciesId, isNull);
      expect(c.photos, isEmpty);
    });

    test('details are stored in SI units', () async {
      final c = await catches.addCatch(tripId: await startTrip());
      await catches.updateDetails(
        c.id,
        const CatchDetails(
          weightGrams: 2350,
          lengthMillimeters: 525,
          depthMillimeters: 3200,
          released: true,
          notes: 'Soltei',
        ),
      );
      final saved = (await catches.watchCatch(c.id).first)!;
      expect(saved.weightGrams, 2350);
      expect(saved.lengthMillimeters, 525);
      expect(saved.depthMillimeters, 3200);
      expect(saved.released, isTrue);
    });

    test('undo restores a deleted catch with its photo', () async {
      final tripId = await startTrip();
      final c = await catches.addCatch(
        tripId: tripId,
        photo: const StoredPhoto(
          relativePath: 'photos/d.jpg',
          width: 1,
          height: 1,
        ),
      );
      await catches.deleteCatch(c.id);
      expect(await catches.watchCatchesForTrip(tripId).first, isEmpty);
      await catches.restoreCatch(c.id);
      final restored = (await catches.watchCatchesForTrip(tripId).first).single;
      expect(restored.photos, hasLength(1));
    });

    test('lists newest first with all photos grouped', () async {
      final tripId = await startTrip();
      final first = await catches.addCatch(tripId: tripId);
      await catches.addPhoto(
        first.id,
        const StoredPhoto(relativePath: 'photos/1.jpg', width: 1, height: 1),
      );
      await catches.addPhoto(
        first.id,
        const StoredPhoto(relativePath: 'photos/2.jpg', width: 1, height: 1),
      );
      deps.clock.advance(const Duration(minutes: 5));
      final second = await catches.addCatch(tripId: tripId);
      final list = await catches.watchCatchesForTrip(tripId).first;
      expect(list.map((c) => c.id), [second.id, first.id]);
      expect(list.last.photos, hasLength(2));
    });

    test('species usage counts only live catches', () async {
      final tripId = await startTrip();
      await catches.addCatch(tripId: tripId, speciesId: 'hoplias-malabaricus');
      await catches.addCatch(tripId: tripId, speciesId: 'hoplias-malabaricus');
      final x = await catches.addCatch(
        tripId: tripId,
        speciesId: 'cyprinus-carpio',
      );
      await catches.addCatch(tripId: tripId);
      await catches.deleteCatch(x.id);
      expect(await catches.watchSpeciesUsage().first, {
        'hoplias-malabaricus': 2,
      });
    });
  });
}
