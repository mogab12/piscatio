import 'package:freezed_annotation/freezed_annotation.dart';

part 'species.freezed.dart';
part 'species.g.dart';

enum Habitat { freshwater, brackish, saltwater }

/// Language code used for alternative scientific names (taxonomic synonyms).
const scientificSynonymLang = 'la';

@freezed
abstract class SpeciesName with _$SpeciesName {
  const factory SpeciesName({
    /// `pt`, `en`, `es`, or [scientificSynonymLang].
    required String lang,
    required String name,
    @Default(false) bool isPrimary,

    /// Optional ISO country where this name is used (e.g. `AR` for tararira).
    String? region,

    /// Translation needs human review before it is considered final.
    @Default(false) bool needsReview,
  }) = _SpeciesName;

  factory SpeciesName.fromJson(Map<String, dynamic> json) =>
      _$SpeciesNameFromJson(json);
}

@freezed
abstract class Species with _$Species {
  const factory Species({
    /// Stable slug, never changes even if the scientific name does.
    required String id,
    required String scientificName,
    @Default(<Habitat>[]) List<Habitat> habitats,

    /// Continents/countries where the species is commonly fished
    /// (`SA`, `NA`, `BR`, `US`…). Used to rank the catalog.
    @Default(<String>[]) List<String> regionTags,
    @Default(<SpeciesName>[]) List<SpeciesName> names,
    @Default(false) bool isCustom,
  }) = _Species;

  const Species._();

  factory Species.fromJson(Map<String, dynamic> json) =>
      _$SpeciesFromJson(json);

  /// Best common name for [lang]: primary name in that language, then any
  /// name in it, then English, then the scientific name.
  String displayName(String lang) {
    SpeciesName? pick(String l) =>
        names.where((n) => n.lang == l && n.isPrimary).firstOrNull ??
        names.where((n) => n.lang == l).firstOrNull;
    return (pick(lang) ?? pick('en'))?.name ?? scientificName;
  }
}
