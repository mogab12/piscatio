import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../domain/models/weather.dart';
import '../db/app_database.dart';

class WeatherRepository {
  WeatherRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  Stream<TripWeather?> watchForTrip(String tripId) =>
      _query(tripId).watchSingleOrNull().map((r) => r?.toModel());

  Future<TripWeather?> forTrip(String tripId) async =>
      (await _query(tripId).getSingleOrNull())?.toModel();

  SimpleSelectStatement<$WeatherSnapshotsTable, WeatherRow> _query(
    String tripId,
  ) => _db.select(_db.weatherSnapshots)..where((w) => w.tripId.equals(tripId));

  /// Clears any old values and shows "waiting for weather".
  Future<void> markPending(String tripId) => _put(
    WeatherSnapshotsCompanion.insert(
      tripId: tripId,
      status: WeatherStatus.pending,
      updatedAt: _clock.now(),
    ),
  );

  Future<void> markUnavailable(String tripId) => _put(
    WeatherSnapshotsCompanion.insert(
      tripId: tripId,
      status: WeatherStatus.unavailable,
      updatedAt: _clock.now(),
    ),
  );

  Future<void> save(TripWeather w) => _put(
    WeatherSnapshotsCompanion.insert(
      tripId: w.tripId,
      status: w.status,
      source: Value(w.source),
      fetchedAt: Value(w.fetchedAt),
      temperatureC: Value(w.temperatureC),
      pressureHpa: Value(w.pressureHpa),
      pressureTrend3hHpa: Value(w.pressureTrend3hHpa),
      windSpeedKmh: Value(w.windSpeedKmh),
      windDirectionDeg: Value(w.windDirectionDeg),
      precipitationMm: Value(w.precipitationMm),
      humidityPct: Value(w.humidityPct),
      hourlyJson: Value(jsonEncode([for (final h in w.hourly) h.toJson()])),
      updatedAt: _clock.now(),
    ),
  );

  Future<void> _put(WeatherSnapshotsCompanion row) =>
      _db.into(_db.weatherSnapshots).insertOnConflictUpdate(row);
}

extension on WeatherRow {
  TripWeather toModel() => TripWeather(
    tripId: tripId,
    status: status,
    source: source,
    fetchedAt: fetchedAt?.toUtc(),
    temperatureC: temperatureC,
    pressureHpa: pressureHpa,
    pressureTrend3hHpa: pressureTrend3hHpa,
    windSpeedKmh: windSpeedKmh,
    windDirectionDeg: windDirectionDeg,
    precipitationMm: precipitationMm,
    humidityPct: humidityPct,
    hourly: hourlyJson == null
        ? const []
        : [
            for (final h in jsonDecode(hourlyJson!) as List<dynamic>)
              HourlyWeather.fromJson(h as Map<String, dynamic>),
          ],
  );
}
