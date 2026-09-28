import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/background.dart';
import '../../../core/device.dart';
import '../../../core/location/location_service.dart';
import '../../../core/providers.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/trip.dart';

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
    await _ref
        .read(tripRepositoryProvider)
        .setLocation(tripId, fix.point, accuracyMeters: fix.accuracyMeters);
    await _ref.read(backgroundWorkProvider).placeNameFor(tripId);
  }

  /// Ends the trip and queues its weather (published 2–3 days later).
  Future<void> finishTrip(String tripId) async {
    await _ref.read(tripRepositoryProvider).finishTrip(tripId);
    await _ref.read(backgroundWorkProvider).weatherFor(tripId);
  }

  Future<void> deleteTrip(String tripId) async {
    await _ref.read(tripRepositoryProvider).deleteTrip(tripId);
    await _ref.read(backgroundWorkProvider).cancelFor(tripId);
  }

  /// Saves edits; new times or place mean new weather, and a place without
  /// region gets one looked up.
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
  }

  Future<void> setPrivacy(Trip trip, PrivacyLevel level) =>
      updateTrip(trip.copyWith(privacyLevel: level));
}

final tripControllerProvider = Provider(TripController.new);
