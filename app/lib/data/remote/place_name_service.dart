import 'dart:ui';

import 'package:geocoding/geocoding.dart' as geo;

import '../../domain/models/geo_point.dart';

/// A place found by name.
class PlaceResult {
  const PlaceResult({required this.point, required this.name, this.region});

  final GeoPoint point;

  /// What to call it ("Represa de Furnas"), editable afterwards.
  final String name;

  /// City/state level ("Alfenas, MG"), when known.
  final String? region;
}

/// Turns coordinates into a city/state level description ("Cuiabá, MT"),
/// and names into places.
abstract interface class PlaceNameService {
  /// Null when the platform finds nothing. Throws on network failure.
  Future<String?> regionFor(GeoPoint point, {required String languageCode});

  /// Places matching [query], best first; empty when none. Throws on
  /// network failure.
  Future<List<PlaceResult>> search(
    String query, {
    required String languageCode,
  });
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
    // The locale goes with each call: the plugin's constructor drops it.
    final places = await geo.Geocoding().placemarkFromCoordinates(
      rounded.latitude,
      rounded.longitude,
      locale: Locale(languageCode),
    );
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

  @override
  Future<List<PlaceResult>> search(
    String query, {
    required String languageCode,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final geocoder = geo.Geocoding();
    final locale = Locale(languageCode);
    final found = await geocoder.locationFromAddress(q, locale: locale);
    final results = <PlaceResult>[];
    for (final l in found.take(5)) {
      final point = GeoPoint(l.latitude, l.longitude);
      final marks = await geocoder.placemarkFromCoordinates(
        l.latitude,
        l.longitude,
        locale: locale,
      );
      final p = marks.firstOrNull;
      results.add(
        PlaceResult(
          point: point,
          name: placeName(p?.name, p?.locality, fallback: q),
          region: p == null
              ? null
              : composeRegion(
                  locality: p.locality,
                  subAdministrativeArea: p.subAdministrativeArea,
                  administrativeArea: p.administrativeArea,
                  country: p.country,
                ),
        ),
      );
    }
    return results;
  }
}

/// A readable name: the place's own name unless it is just a number
/// (house numbers, postal codes), then the town, then what was typed.
String placeName(String? name, String? locality, {required String fallback}) {
  final n = name?.trim();
  if (n != null && n.isNotEmpty && !RegExp(r'^[\d\s-]+$').hasMatch(n)) {
    return n;
  }
  final l = locality?.trim();
  return l == null || l.isEmpty ? fallback : l;
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
