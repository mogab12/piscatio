import '../models/enums.dart';

/// The only place text a card may show, by privacy level. Cards never get
/// coordinates at all; this decides between nothing, the region and the
/// place name.
///
/// - private / friends (until social features exist): nothing
/// - approximate: the region ("Cuiabá, MT")
/// - exact: the place name, else the region
String? cardPlace(PrivacyLevel level, {String? name, String? region}) {
  String? clean(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
  return switch (level) {
    PrivacyLevel.private || PrivacyLevel.friends => null,
    PrivacyLevel.approximate => clean(region),
    PrivacyLevel.exact => clean(name) ?? clean(region),
  };
}
