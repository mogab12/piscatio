import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/ids.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/geo_point.dart';
import '../../domain/models/trip.dart';
import '../../domain/services/moon.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class TripRepository {
  TripRepository(this._db, this._clock, this._ids);

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  /// The trip in progress, if any. Only one trip can be active at a time.
  Stream<Trip?> watchActiveTrip() =>
      _activeQuery().watchSingleOrNull().map((row) => row?.toModel());

  // One-shot reads use get(), never watch().first: Drift shares identical
  // stream queries, and a stream already watched by the UI may deliver its
  // events in another zone.
  Future<Trip?> activeTrip() async =>
      (await _activeQuery().getSingleOrNull())?.toModel();

  SimpleSelectStatement<$TripsTable, TripRow> _activeQuery() =>
      _db.select(_db.trips)
        ..where((t) => t.deletedAt.isNull() & t.endedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
        ..limit(1);

  Stream<Trip?> watchTrip(String id) =>
      _byId(id).watchSingleOrNull().map((row) => row?.toModel());

  Future<Trip?> getTrip(String id) async =>
      (await _byId(id).getSingleOrNull())?.toModel();

  SimpleSelectStatement<$TripsTable, TripRow> _byId(String id) =>
      _db.select(_db.trips)
        ..where((t) => t.id.equals(id) & t.deletedAt.isNull());

  /// Trips with catch counts, most recent first. Pass [limit] for the home
  /// screen; omit it for the full history.
  Stream<List<TripOverview>> watchOverviews({int? limit}) {
    final c = _db.catches;
    // The photo join repeats catch rows, so count distinct catch ids.
    final catchCount = c.id.count(distinct: true);
    final speciesCount = c.speciesId.count(distinct: true);
    final maxWeight = c.weightG.max();
    final maxLength = c.lengthMm.max();
    // Photo files are named by UUID v7, so the smallest path is the trip's
    // first photo: a good enough cover for lists.
    final cover = _db.catchPhotos.relativePath.min();

    final query =
        _db.select(_db.trips).join([
            leftOuterJoin(
              c,
              c.tripId.equalsExp(_db.trips.id) & c.deletedAt.isNull(),
            ),
            leftOuterJoin(
              _db.catchPhotos,
              _db.catchPhotos.catchId.equalsExp(c.id) &
                  _db.catchPhotos.deletedAt.isNull(),
            ),
          ])
          ..where(_db.trips.deletedAt.isNull())
          ..addColumns([catchCount, speciesCount, maxWeight, maxLength, cover])
          ..groupBy([_db.trips.id])
          ..orderBy([OrderingTerm.desc(_db.trips.startedAt)]);
    if (limit != null) query.limit(limit);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          TripOverview(
            trip: row.readTable(_db.trips).toModel(),
            catchCount: row.read(catchCount) ?? 0,
            speciesCount: row.read(speciesCount) ?? 0,
            maxWeightGrams: row.read(maxWeight),
            maxLengthMillimeters: row.read(maxLength),
            coverPhotoPath: row.read(cover),
          ),
      ],
    );
  }

  /// Starts a trip now. Fails if another trip is already active.
  Future<Trip> startTrip({
    required String timezone,
    required PrivacyLevel privacy,
    GeoPoint? location,
    double? accuracyMeters,
  }) {
    return _db.transaction(() async {
      if (await activeTrip() != null) {
        throw StateError('A trip is already in progress');
      }
      final now = _clock.now();
      return _insert(
        startedAt: now,
        endedAt: null,
        timezone: timezone,
        privacy: privacy,
        location: location,
        accuracyMeters: accuracyMeters,
        isRetroactive: false,
      );
    });
  }

  /// Records a past trip (retroactive entry).
  Future<Trip> createPastTrip({
    required DateTime startedAt,
    required DateTime endedAt,
    required String timezone,
    required PrivacyLevel privacy,
    GeoPoint? location,
    String? locationName,
  }) {
    if (!endedAt.isAfter(startedAt)) {
      throw ArgumentError('endedAt must be after startedAt');
    }
    return _insert(
      startedAt: startedAt.toUtc(),
      endedAt: endedAt.toUtc(),
      timezone: timezone,
      privacy: privacy,
      location: location,
      locationName: locationName,
      isRetroactive: true,
    );
  }

  Future<Trip> _insert({
    required DateTime startedAt,
    required DateTime? endedAt,
    required String timezone,
    required PrivacyLevel privacy,
    required bool isRetroactive,
    GeoPoint? location,
    double? accuracyMeters,
    String? locationName,
  }) async {
    final now = _clock.now();
    final moon = moonAt(startedAt);
    final row = TripsCompanion.insert(
      id: _ids.newId(),
      startedAt: startedAt,
      endedAt: Value(endedAt),
      timezone: timezone,
      latitude: Value(location?.latitude),
      longitude: Value(location?.longitude),
      locationAccuracyM: Value(accuracyMeters),
      locationName: Value(locationName),
      privacyLevel: privacy,
      moonPhase: moon.phase,
      moonIllumination: moon.illumination,
      isRetroactive: Value(isRetroactive),
      createdAt: now,
      updatedAt: now,
    );
    final inserted = await _db.into(_db.trips).insertReturning(row);
    return inserted.toModel();
  }

  Future<void> finishTrip(String id) async {
    final now = _clock.now();
    await (_db.update(_db.trips)
          ..where((t) => t.id.equals(id) & t.endedAt.isNull()))
        .write(TripsCompanion(endedAt: Value(now), updatedAt: Value(now)));
  }

  /// Sets the location once GPS answers (it may arrive after the trip starts).
  Future<void> setLocation(
    String id,
    GeoPoint location, {
    double? accuracyMeters,
  }) {
    return _write(
      id,
      TripsCompanion(
        latitude: Value(location.latitude),
        longitude: Value(location.longitude),
        locationAccuracyM: Value(accuracyMeters),
      ),
    );
  }

  /// Sets the region found by geocoding, unless the user already typed one.
  Future<void> fillRegion(String id, String region) async {
    await (_db.update(
      _db.trips,
    )..where((t) => t.id.equals(id) & t.locationRegion.isNull())).write(
      TripsCompanion(
        locationRegion: Value(region),
        updatedAt: Value(_clock.now()),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
  }

  /// Saves user edits. Recomputes the moon if the start time changed.
  Future<void> updateTrip(Trip trip) {
    if (trip.endedAt != null && !trip.endedAt!.isAfter(trip.startedAt)) {
      throw ArgumentError('endedAt must be after startedAt');
    }
    final moon = moonAt(trip.startedAt);
    return _write(
      trip.id,
      TripsCompanion(
        startedAt: Value(trip.startedAt.toUtc()),
        endedAt: Value(trip.endedAt?.toUtc()),
        latitude: Value(trip.location?.latitude),
        longitude: Value(trip.location?.longitude),
        locationName: Value(trip.locationName),
        locationRegion: Value(trip.locationRegion),
        privacyLevel: Value(trip.privacyLevel),
        moonPhase: Value(moon.phase),
        moonIllumination: Value(moon.illumination),
        notes: Value(trip.notes),
      ),
    );
  }

  /// Soft-deletes the trip together with its catches and photos (the
  /// tombstones sync like any edit).
  Future<void> deleteTrip(String id) {
    final now = Value(_clock.now());
    const pending = Value(SyncStatus.pending);
    return _db.transaction(() async {
      final catchIds = _db.selectOnly(_db.catches)
        ..addColumns([_db.catches.id])
        ..where(_db.catches.tripId.equals(id));
      await (_db.update(
            _db.catchPhotos,
          )..where((p) => p.catchId.isInQuery(catchIds) & p.deletedAt.isNull()))
          .write(
            CatchPhotosCompanion(
              deletedAt: now,
              updatedAt: now,
              syncStatus: pending,
            ),
          );
      await (_db.update(
        _db.catches,
      )..where((c) => c.tripId.equals(id) & c.deletedAt.isNull())).write(
        CatchesCompanion(deletedAt: now, updatedAt: now, syncStatus: pending),
      );
      await (_db.update(_db.trips)..where((t) => t.id.equals(id))).write(
        TripsCompanion(deletedAt: now, updatedAt: now, syncStatus: pending),
      );
    });
  }

  Future<void> _write(String id, TripsCompanion changes) async {
    await (_db.update(_db.trips)..where((t) => t.id.equals(id))).write(
      changes.copyWith(
        updatedAt: Value(_clock.now()),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
  }
}
