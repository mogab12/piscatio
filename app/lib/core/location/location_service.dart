import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/models/geo_point.dart';

enum LocationAccess { granted, denied, deniedForever, serviceDisabled }

class LocationFix {
  const LocationFix(this.point, this.accuracyMeters);

  final GeoPoint point;
  final double accuracyMeters;
}

/// GPS behind an interface so screens can be tested without a device.
abstract interface class LocationService {
  Future<LocationAccess> access();
  Future<LocationAccess> requestAccess();

  /// Current position, or null if unavailable within [timeout]. Never
  /// throws: a trip must start even without GPS.
  Future<LocationFix?> currentFix({Duration timeout});
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationAccess> access() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }
    return _map(await Geolocator.checkPermission());
  }

  @override
  Future<LocationAccess> requestAccess() async {
    final current = await Geolocator.checkPermission();
    if (current == LocationPermission.deniedForever) {
      return LocationAccess.deniedForever;
    }
    return _map(await Geolocator.requestPermission());
  }

  @override
  Future<LocationFix?> currentFix({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      if (await access() != LocationAccess.granted) return null;
      final p = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(timeLimit: timeout),
      );
      return LocationFix(GeoPoint(p.latitude, p.longitude), p.accuracy);
    } on Exception {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) return null;
      return LocationFix(
        GeoPoint(last.latitude, last.longitude),
        last.accuracy,
      );
    }
  }

  static LocationAccess _map(LocationPermission p) => switch (p) {
    LocationPermission.always ||
    LocationPermission.whileInUse => LocationAccess.granted,
    LocationPermission.deniedForever => LocationAccess.deniedForever,
    _ => LocationAccess.denied,
  };
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);
