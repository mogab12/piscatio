import 'geo_point.dart';

/// Kinds of business anglers look for. Names match the server's.
enum VenueKind { payLake, lodge, guide, shop, marina, charter, other }

VenueKind _kind(Object? v) => switch (v) {
  'pay_lake' => VenueKind.payLake,
  'lodge' => VenueKind.lodge,
  'guide' => VenueKind.guide,
  'shop' => VenueKind.shop,
  'marina' => VenueKind.marina,
  'charter' => VenueKind.charter,
  _ => VenueKind.other,
};

/// A business in the app: a pay lake (pesqueiro), lodge, guide, tackle
/// shop… Its profile, location included, is public: a business address is
/// not a secret spot.
class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.kind,
    this.city = '',
    this.state = '',
    this.location,
    this.description = '',
    this.species = const [],
    this.amenities = const [],
    this.phone = '',
    this.whatsapp = '',
    this.website = '',
    this.instagram = '',
    this.verified = false,
    this.distanceKm,
    this.isFavorite = false,
  });

  factory Venue.fromJson(Map<String, Object?> j) {
    final lat = (j['latitude'] as num?)?.toDouble();
    final lng = (j['longitude'] as num?)?.toDouble();
    List<String> strings(Object? v) => [
      for (final s in (v as List? ?? const [])) '$s',
    ];
    return Venue(
      id: j['id']! as String,
      name: j['name'] as String? ?? '',
      kind: _kind(j['kind']),
      city: j['city'] as String? ?? '',
      state: j['state'] as String? ?? '',
      location: lat == null || lng == null ? null : GeoPoint(lat, lng),
      description: j['description'] as String? ?? '',
      species: strings(j['species']),
      amenities: strings(j['amenities']),
      phone: j['phone'] as String? ?? '',
      whatsapp: j['whatsapp'] as String? ?? '',
      website: j['website'] as String? ?? '',
      instagram: j['instagram'] as String? ?? '',
      verified: j['verified'] == true,
      distanceKm: (j['distance_km'] as num?)?.toDouble(),
      isFavorite: j['is_favorite'] == true,
    );
  }

  final String id;
  final String name;
  final VenueKind kind;
  final String city;
  final String state;
  final GeoPoint? location;
  final String description;

  /// Catalog species ids found there.
  final List<String> species;
  final List<String> amenities;
  final String phone;
  final String whatsapp;
  final String website;
  final String instagram;

  /// Checked by the Piscatio team.
  final bool verified;

  /// From the point searched around, when there was one.
  final double? distanceKm;
  final bool isFavorite;

  /// "Cuiabá, MT".
  String get place => [city, state].where((s) => s.isNotEmpty).join(', ');
}

/// Switches sent by the server: features ship turned off and are opened
/// remotely (see backend `flags`). Unknown keys are off.
class FeatureFlags {
  const FeatureFlags([this._on = const {}]);

  factory FeatureFlags.fromJson(Map<String, Object?> j) => FeatureFlags({
    for (final MapEntry(:key, :value)
        in ((j['features'] as Map?) ?? const {}).entries)
      if (value == true) key as String,
  });

  static const none = FeatureFlags();

  /// Venues: search, a trip's venue, the insights consent.
  static const venues = 'venues';

  final Set<String> _on;

  bool isOn(String key) => _on.contains(key);

  Map<String, Object?> toJson() => {
    'features': {for (final k in _on) k: true},
  };
}
