import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/models/species.dart';
import '../settings/application/preferences.dart';

/// Common name of a species in the app language; null id or unknown species
/// returns null (callers show "Unidentified species").
final speciesNameProvider = Provider.family<String?, String?>((ref, id) {
  if (id == null) return null;
  final species = ref.watch(speciesByIdProvider)[id];
  if (species == null) return null;
  return species.displayName(ref.watch(effectiveLanguageProvider));
});

/// Scientific name to show under the common name (custom species have none).
String? scientificNameOf(Species? species) =>
    species == null || species.isCustom ? null : species.scientificName;
