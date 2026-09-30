import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/domain/models/venue.dart';

void main() {
  test('a venue reads the server JSON', () {
    final v = Venue.fromJson({
      'id': 'v1',
      'name': 'Pesqueiro São José',
      'kind': 'pay_lake',
      'city': 'Cuiabá',
      'state': 'MT',
      'latitude': -15.6,
      'longitude': -56.1,
      'species': ['piaractus-mesopotamicus'],
      'verified': true,
      'distance_km': 2.4,
      'is_favorite': false,
    });
    expect(v.kind, VenueKind.payLake);
    expect(v.place, 'Cuiabá, MT');
    expect(v.location, const GeoPoint(-15.6, -56.1));
    expect(v.species, ['piaractus-mesopotamicus']);
    expect(v.verified, isTrue);
    expect(v.distanceKm, 2.4);
    // Unknown kinds and missing fields are tolerated.
    final bare = Venue.fromJson({'id': 'v2', 'kind': 'spaceport'});
    expect(bare.kind, VenueKind.other);
    expect(bare.location, isNull);
    expect(bare.place, '');
  });

  test('feature flags: only what the server turned on', () {
    final flags = FeatureFlags.fromJson({
      'features': {'venues': true, 'social': false},
    });
    expect(flags.isOn('venues'), isTrue);
    expect(flags.isOn('social'), isFalse);
    expect(flags.isOn('anything'), isFalse);
    expect(FeatureFlags.fromJson(flags.toJson()).isOn('venues'), isTrue);
    expect(FeatureFlags.none.isOn('venues'), isFalse);
  });
}
