import 'dart:ui';

import 'package:geocoding/geocoding.dart' as geo;

import '../../domain/models/geo_point.dart';

/// Turns coordinates into a city/state level description ("Cuiabá, MT").
abstract interface class PlaceNameService {
  /// Null when the platform finds nothing. Throws on network failure.
  Future<String?> regionFor(GeoPoint point, {required String languageCode});
}

/// Uses the platform geocoder (Google on Android, Apple on iOS), which
/// needs a connection. Only a ~1 km rounded point is sent: city-level
/// names do not need more, and the exact spot stays on the phone.
class PlatformPlaceNameService implements PlaceNameService {
  const PlatformPlaceNameService();

  @override
  Future<String?> regionFor(
    GeoPoint point, {
    required String languageCode,
  }) async {
    final rounded = roundForLookup(point);
    final places = await geo.Geocoding(locale: Locale(languageCode))
        .placemarkFromCoordinates(rounded.latitude, rounded.longitude);
    for (final p in places) {
      final region = composeRegion(
        locality: p.locality,
        subAdministrativeArea: p.subAdministrativeArea,
        administrativeArea: p.administrativeArea,
        country: p.country,
      );
      if (region != null) return region;
    }
    return null;
  }
}

/// Two decimals ≈ 1.1 km.
GeoPoint roundForLookup(GeoPoint p) => GeoPoint(
  double.parse(p.latitude.toStringAsFixed(2)),
  double.parse(p.longitude.toStringAsFixed(2)),
);

/// "City, State"; falls back to the county, then the country.
String? composeRegion({
  String? locality,
  String? subAdministrativeArea,
  String? administrativeArea,
  String? country,
}) {
  String? clean(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
  final city = clean(locality) ?? clean(subAdministrativeArea);
  final state = clean(administrativeArea);
  final parts = [?city, if (state != null && state != city) state];
  if (parts.isNotEmpty) return parts.join(', ');
  return clean(country);
}
