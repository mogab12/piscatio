// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/data/db/app_database.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // v1 → v2 recreates weather_snapshots (never written in v1) and adds
  // jobs; every user table must come through untouched.
  test(
    'migration from v1 to v2 keeps trips, catches, species and settings',
    () async {
      const t = '2026-09-12T09:00:00.000Z';
      final oldTripsData = <v1.TripsData>[
        const v1.TripsData(
          createdAt: t,
          updatedAt: t,
          syncStatus: 'pending',
          id: 'trip-1',
          startedAt: t,
          endedAt: '2026-09-12T12:00:00.000Z',
          timezone: 'America/Cuiaba',
          latitude: -16.52,
          longitude: -56.41,
          locationName: 'Rio Cuiabá',
          privacyLevel: 'approximate',
          moonPhase: 'newMoon',
          moonIllumination: 0.02,
          isRetroactive: 0,
        ),
      ];
      final expectedNewTripsData = <v2.TripsData>[
        const v2.TripsData(
          createdAt: t,
          updatedAt: t,
          syncStatus: 'pending',
          id: 'trip-1',
          startedAt: t,
          endedAt: '2026-09-12T12:00:00.000Z',
          timezone: 'America/Cuiaba',
          latitude: -16.52,
          longitude: -56.41,
          locationName: 'Rio Cuiabá',
          privacyLevel: 'approximate',
          moonPhase: 'newMoon',
          moonIllumination: 0.02,
          isRetroactive: 0,
        ),
      ];

      final oldWeatherSnapshotsData = <v1.WeatherSnapshotsData>[];
      final expectedNewWeatherSnapshotsData = <v2.WeatherSnapshotsData>[];

      final oldSpeciesData = <v1.SpeciesData>[
        const v1.SpeciesData(
          createdAt: t,
          updatedAt: t,
          syncStatus: 'pending',
          id: 'hoplias-malabaricus',
          scientificName: 'Hoplias malabaricus',
          habitats: 'freshwater',
          regionTags: 'SA',
          isCustom: 0,
        ),
      ];
      final expectedNewSpeciesData = <v2.SpeciesData>[
        const v2.SpeciesData(
          createdAt: t,
          updatedAt: t,
          syncStatus: 'pending',
          id: 'hoplias-malabaricus',
          scientificName: 'Hoplias malabaricus',
          habitats: 'freshwater',
          regionTags: 'SA',
          isCustom: 0,
        ),
      ];

      final oldSpeciesNamesData = <v1.SpeciesNamesData>[];
      final expectedNewSpeciesNamesData = <v2.SpeciesNamesData>[];

      final oldBaitsData = <v1.BaitsData>[];
      final expectedNewBaitsData = <v2.BaitsData>[];

      final oldGearData = <v1.GearData>[];
      final expectedNewGearData = <v2.GearData>[];

      final oldCatchesData = <v1.CatchesData>[
        const v1.CatchesData(
          createdAt: t,
          updatedAt: t,
          syncStatus: 'pending',
          id: 'catch-1',
          tripId: 'trip-1',
          speciesId: 'hoplias-malabaricus',
          caughtAt: t,
          weightG: 1450,
          lengthMm: 480,
          released: 1,
        ),
      ];
      final expectedNewCatchesData = <v2.CatchesData>[
        const v2.CatchesData(
          createdAt: t,
          updatedAt: t,
          syncStatus: 'pending',
          id: 'catch-1',
          tripId: 'trip-1',
          speciesId: 'hoplias-malabaricus',
          caughtAt: t,
          weightG: 1450,
          lengthMm: 480,
          released: 1,
        ),
      ];

      final oldCatchPhotosData = <v1.CatchPhotosData>[];
      final expectedNewCatchPhotosData = <v2.CatchPhotosData>[];

      final oldSettingsData = <v1.SettingsData>[
        const v1.SettingsData(key: 'language', value: 'es'),
      ];
      final expectedNewSettingsData = <v2.SettingsData>[
        const v2.SettingsData(key: 'language', value: 'es'),
      ];

      await verifier.testWithDataIntegrity(
        oldVersion: 1,
        newVersion: 2,
        createOld: v1.DatabaseAtV1.new,
        createNew: v2.DatabaseAtV2.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.insertAll(oldDb.trips, oldTripsData);
          batch.insertAll(oldDb.weatherSnapshots, oldWeatherSnapshotsData);
          batch.insertAll(oldDb.species, oldSpeciesData);
          batch.insertAll(oldDb.speciesNames, oldSpeciesNamesData);
          batch.insertAll(oldDb.baits, oldBaitsData);
          batch.insertAll(oldDb.gear, oldGearData);
          batch.insertAll(oldDb.catches, oldCatchesData);
          batch.insertAll(oldDb.catchPhotos, oldCatchPhotosData);
          batch.insertAll(oldDb.settings, oldSettingsData);
        },
        validateItems: (newDb) async {
          expect(expectedNewTripsData, await newDb.select(newDb.trips).get());
          expect(
            expectedNewWeatherSnapshotsData,
            await newDb.select(newDb.weatherSnapshots).get(),
          );
          expect(
            expectedNewSpeciesData,
            await newDb.select(newDb.species).get(),
          );
          expect(
            expectedNewSpeciesNamesData,
            await newDb.select(newDb.speciesNames).get(),
          );
          expect(expectedNewBaitsData, await newDb.select(newDb.baits).get());
          expect(expectedNewGearData, await newDb.select(newDb.gear).get());
          expect(
            expectedNewCatchesData,
            await newDb.select(newDb.catches).get(),
          );
          expect(
            expectedNewCatchPhotosData,
            await newDb.select(newDb.catchPhotos).get(),
          );
          expect(
            expectedNewSettingsData,
            await newDb.select(newDb.settings).get(),
          );
        },
      );
    },
  );

  // v2 → v3 only adds the place_maps cache; trips and pending jobs stay.
  test('migration from v2 to v3 keeps trips and pending jobs', () async {
    const t = '2026-09-12T09:00:00.000Z';
    const trip = (
      createdAt: t,
      updatedAt: t,
      syncStatus: 'pending',
      id: 'trip-1',
      startedAt: t,
      endedAt: '2026-09-12T12:00:00.000Z',
      timezone: 'America/Cuiaba',
      latitude: -16.52,
      longitude: -56.41,
      privacyLevel: 'approximate',
      moonPhase: 'newMoon',
      moonIllumination: 0.02,
      isRetroactive: 0,
    );
    const job = (
      id: 'job-1',
      kind: 'weather',
      subjectId: 'trip-1',
      attempts: 2,
      nextAttemptAt: t,
      createdAt: t,
      updatedAt: t,
    );
    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch
          ..insert(
            oldDb.trips,
            const v2.TripsData(
              createdAt: t,
              updatedAt: t,
              syncStatus: 'pending',
              id: 'trip-1',
              startedAt: t,
              endedAt: '2026-09-12T12:00:00.000Z',
              timezone: 'America/Cuiaba',
              latitude: -16.52,
              longitude: -56.41,
              privacyLevel: 'approximate',
              moonPhase: 'newMoon',
              moonIllumination: 0.02,
              isRetroactive: 0,
            ),
          )
          ..insert(
            oldDb.jobs,
            const v2.JobsData(
              id: 'job-1',
              kind: 'weather',
              subjectId: 'trip-1',
              attempts: 2,
              nextAttemptAt: t,
              createdAt: t,
              updatedAt: t,
            ),
          );
      },
      validateItems: (newDb) async {
        final trips = await newDb.select(newDb.trips).get();
        expect(trips.single.id, trip.id);
        expect(trips.single.latitude, trip.latitude);
        expect(trips.single.privacyLevel, trip.privacyLevel);
        final jobs = await newDb.select(newDb.jobs).get();
        expect(jobs.single.id, job.id);
        expect(jobs.single.attempts, job.attempts);
        expect(await newDb.select(newDb.placeMaps).get(), isEmpty);
      },
    );
  });
}
