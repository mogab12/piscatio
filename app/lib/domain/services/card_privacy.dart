import '../models/enums.dart';

/// The only place text a card may show, by privacy level and audience.
/// Cards never get coordinates at all; this decides between nothing, the
/// region and the place name.
///
/// - private: nothing
/// - friends: the region, only on cards shown to friends; nothing otherwise
/// - approximate: the region ("Cuiabá, MT")
/// - exact: the place name, else the region
String? cardPlace(
  PrivacyLevel level, {
  String? name,
  String? region,
  CardAudience audience = CardAudience.everyone,
}) {
  String? clean(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
  return switch (level) {
    PrivacyLevel.private => null,
    PrivacyLevel.friends =>
      audience == CardAudience.friends ? clean(region) : null,
    PrivacyLevel.approximate => clean(region),
    PrivacyLevel.exact => clean(name) ?? clean(region),
  };
}
