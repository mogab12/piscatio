import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/background.dart';
import '../../../core/device.dart';
import '../../../core/location/location_service.dart';
import '../../../core/providers.dart';
import '../../../data/media/photo_importer.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/geo_point.dart';
import '../../../domain/models/trip.dart';
import '../../../domain/services/catch_time.dart';

class TripController {
  TripController(this._ref);

  final Ref _ref;

  /// Starts a trip instantly. Location arrives later (GPS can take a while
  /// or be unavailable) and is attached when it does.
  Future<Trip> startTrip() async {
    final settings = await _ref.read(settingsRepositoryProvider).read();
    final timezone = await _ref.read(deviceTimezoneProvider.future);
    final trips = _ref.read(tripRepositoryProvider);
    final trip = await trips.startTrip(
      timezone: timezone,
      privacy: settings.defaultPrivacy,
    );
    unawaited(_attachLocation(trip.id));
    return trip;
  }

  Future<void> _attachLocation(String tripId) async {
    try {
      await _locate(tripId);
    } on Object {
      // No location is a normal outcome (no signal, permission denied).
    }
  }

  Future<void> _locate(String tripId) async {
    final location = _ref.read(locationServiceProvider);
    var access = await location.access();
    if (access == LocationAccess.denied) {
      access = await location.requestAccess();
    }
    if (access != LocationAccess.granted) return;
    final fix = await location.currentFix();
    if (fix == null) return;
    final trips = _ref.read(tripRepositoryProvider);
    await trips.setLocation(
      tripId,
      fix.point,
      accuracyMeters: fix.accuracyMeters,
    );
    final work = _ref.read(backgroundWorkProvider);
    await work.placeNameFor(tripId);
    final trip = await trips.getTrip(tripId);
    if (trip != null) await work.mapFor(tripId, trip.privacyLevel);
  }

  /// Ends the trip and queues its weather (published 2–3 days later).
  Future<void> finishTrip(String tripId) async {
    await _ref.read(tripRepositoryProvider).finishTrip(tripId);
    final work = _ref.read(backgroundWorkProvider);
    await work.weatherFor(tripId);
    await work.syncSoon();
  }

  Future<void> deleteTrip(String tripId) async {
    await _ref.read(tripRepositoryProvider).deleteTrip(tripId);
    final work = _ref.read(backgroundWorkProvider);
    await work.cancelFor(tripId);
    await work.syncSoon();
  }

  /// Saves edits; new times or place mean new weather, a place without
  /// region gets one looked up, a new place or privacy may need a map.
  Future<void> updateTrip(Trip trip) async {
    final repo = _ref.read(tripRepositoryProvider);
    final before = await repo.getTrip(trip.id);
    await repo.updateTrip(trip);
    final work = _ref.read(backgroundWorkProvider);
    final changedWhenOrWhere =
        before == null ||
        before.startedAt != trip.startedAt ||
        before.endedAt != trip.endedAt ||
        before.location != trip.location;
    if (!trip.isActive && changedWhenOrWhere) await work.weatherFor(trip.id);
    if (trip.location != null && (trip.locationRegion ?? '').isEmpty) {
      await work.placeNameFor(trip.id);
    }
    if (trip.location != null &&
        (before?.location != trip.location ||
            before?.privacyLevel != trip.privacyLevel)) {
      await work.mapFor(trip.id, trip.privacyLevel);
    }
  }

  /// Logs a trip after the fact. Each photo becomes a catch at the time it
  /// was taken (when that falls inside the trip), with the place it was
  /// taken; weather and the region are queued like for a live trip.
  Future<Trip> createPastTrip({
    required DateTime startedAt,
    required DateTime endedAt,
    required PrivacyLevel privacy,
    GeoPoint? location,
    String? locationName,
    String? locationRegion,
    List<ImportedPhoto> photos = const [],
  }) async {
    final timezone = await _ref.read(deviceTimezoneProvider.future);
    final trips = _ref.read(tripRepositoryProvider);
    final trip = await trips.createPastTrip(
      startedAt: startedAt,
      endedAt: endedAt,
      timezone: timezone,
      privacy: privacy,
      location: location,
      locationName: locationName,
    );
    if (locationRegion != null) {
      await trips.fillRegion(trip.id, locationRegion);
    }
    final catches = _ref.read(catchRepositoryProvider);
    final now = _ref.read(clockProvider).now();
    for (final p in photos) {
      await catches.addCatch(
        tripId: trip.id,
        caughtAt: defaultCatchTime(
          trip: trip,
          now: now,
          photoTakenAt: p.stored.takenAt,
        ),
        photo: p.stored,
        location: p.exifLocation,
      );
    }
    final work = _ref.read(backgroundWorkProvider);
    await work.weatherFor(trip.id);
    if (location != null && locationRegion == null) {
      await work.placeNameFor(trip.id);
    }
    if (location != null) await work.mapFor(trip.id, privacy);
    await work.syncSoon();
    return trip;
  }

  Future<void> setPrivacy(Trip trip, PrivacyLevel level) =>
      updateTrip(trip.copyWith(privacyLevel: level));
}

final tripControllerProvider = Provider(TripController.new);
