import 'dart:ui';

import '../../../domain/services/ruler_scale.dart';

enum CardStyle { board, chart, tag }

enum CardFormat {
  story(Size(1080, 1920)),
  square(Size(1080, 1080));

  const CardFormat(this.size);

  final Size size;
}

/// The card's accent, in the colors of fishing lures. Each has a shade for
/// deep water, one for white plastic and one for stamp ink on manila.
enum CardAccent {
  red(Color(0xFFFF6A5E), Color(0xFFE4262C), Color(0xFFC4232B)),
  orange(Color(0xFFFF9A3C), Color(0xFFEE7614), Color(0xFFC0580B)),
  chartreuse(Color(0xFFD2E640), Color(0xFF9DB814), Color(0xFF5E7A0A)),
  blue(Color(0xFF5AAEFF), Color(0xFF2B7FD6), Color(0xFF1D5AA6));

  const CardAccent(this.onDark, this.onLight, this.ink);

  final Color onDark;
  final Color onLight;
  final Color ink;
}

/// What the person chose in the card editor.
class CardOptions {
  const CardOptions({
    this.accent = CardAccent.red,
    this.showPlace = true,
    this.showWeather = true,
    this.showBait = true,
    this.caption,
    this.photoChosen = false,
    this.photoPath,
  });

  final CardAccent accent;
  final bool showPlace;

  /// Weather and moon.
  final bool showWeather;
  final bool showBait;

  /// Free text written by the person; empty or null shows nothing.
  final String? caption;

  /// When true, [photoPath] replaces the card's default photo (null = the
  /// card goes without a photo).
  final bool photoChosen;
  final String? photoPath;

  String? get _caption {
    final c = caption?.trim();
    return c == null || c.isEmpty ? null : c;
  }

  CardOptions copyWith({
    CardAccent? accent,
    bool? showPlace,
    bool? showWeather,
    bool? showBait,
    String? caption,
  }) => CardOptions(
    accent: accent ?? this.accent,
    showPlace: showPlace ?? this.showPlace,
    showWeather: showWeather ?? this.showWeather,
    showBait: showBait ?? this.showBait,
    caption: caption ?? this.caption,
    photoChosen: photoChosen,
    photoPath: photoPath,
  );

  CardOptions withPhoto(String? path) => CardOptions(
    accent: accent,
    showPlace: showPlace,
    showWeather: showWeather,
    showBait: showBait,
    caption: caption,
    photoChosen: true,
    photoPath: path,
  );
}

/// Record content, already localized.
class CardRecord {
  const CardRecord.first() : isFirst = true, improvement = null;

  const CardRecord.record({this.improvement}) : isFirst = false;

  final bool isFirst;

  /// "+14%"; null when there was no earlier measurement to compare.
  final String? improvement;
}

class CardMoon {
  const CardMoon({
    required this.illumination,
    required this.waxing,
    required this.label,
    this.southern = false,
  });

  final double illumination;
  final bool waxing;
  final String label;

  /// Seen from the southern hemisphere the lit side is mirrored. Only the
  /// hemisphere is known here, never the coordinates.
  final bool southern;
}

/// A number and its unit, styled apart on cards ("52" big, "cm" small).
class CardQuantity {
  const CardQuantity(this.value, this.unit);

  final String value;
  final String unit;

  @override
  String toString() => '$value $unit';
}

class CardWind {
  const CardWind({required this.fromDegrees, required this.label});

  final double fromDegrees;

  /// "9 km/h SE".
  final String label;
}

/// Everything a catch card shows, localized and in the user's units.
///
/// Deliberately has **no coordinates**: a card cannot leak the spot, only
/// the [place] text allowed by the trip's privacy level.
class CatchCardData {
  const CatchCardData({
    required this.id,
    required this.speciesName,
    required this.dateLabel,
    required this.timeLabel,
    required this.romanDate,
    required this.catchNumber,
    required this.ruler,
    required this.rulerUnit,
    this.moon,
    this.headline = const [],
    this.scientificName,
    this.place,
    this.lengthLabel,
    this.weightLabel,
    this.baitLabel,
    this.released,
    this.photoPath,
    this.photoOptions = const [],
    this.record,
    this.previousRecordLabel,
    this.wind,
    this.temperatureLabel,
    this.pressureLabel,
    this.caption,
  });

  final String id;
  final String speciesName;
  final String? scientificName;
  final String dateLabel;
  final String timeLabel;
  final String romanDate;
  final String? place;
  final String? lengthLabel;
  final String? weightLabel;
  final String? baitLabel;
  final bool? released;

  /// Position of this catch in the user's whole logbook (1-based).
  final int catchNumber;

  /// Absolute path of the photo (EXIF already stripped at import).
  final String? photoPath;

  /// Every photo the person may pick for this card.
  final List<String> photoOptions;
  final RulerScale ruler;

  /// Unit printed at the end of the board ("cm", "lb", "h").
  final String rulerUnit;

  /// The featured measure (length, else weight), split for styling; empty
  /// when the catch was not measured.
  final List<CardQuantity> headline;
  final CardRecord? record;

  /// "46 cm": the best before this catch, for the board's record mark.
  final String? previousRecordLabel;
  final CardMoon? moon;
  final CardWind? wind;
  final String? temperatureLabel;
  final String? pressureLabel;

  /// The person's own words for this card.
  final String? caption;

  /// The card as the person set it up: hidden details removed, the chosen
  /// photo and caption applied. Privacy only ever removes information.
  CatchCardData customized(CardOptions o) => CatchCardData(
    id: id,
    speciesName: speciesName,
    scientificName: scientificName,
    dateLabel: dateLabel,
    timeLabel: timeLabel,
    romanDate: romanDate,
    catchNumber: catchNumber,
    ruler: ruler,
    rulerUnit: rulerUnit,
    headline: headline,
    moon: o.showWeather ? moon : null,
    place: o.showPlace ? place : null,
    lengthLabel: lengthLabel,
    weightLabel: weightLabel,
    baitLabel: o.showBait ? baitLabel : null,
    released: released,
    photoPath: o.photoChosen ? o.photoPath : photoPath,
    photoOptions: photoOptions,
    record: record,
    previousRecordLabel: previousRecordLabel,
    wind: o.showWeather ? wind : null,
    temperatureLabel: o.showWeather ? temperatureLabel : null,
    pressureLabel: o.showWeather ? pressureLabel : null,
    caption: o._caption,
  );
}

/// One catch as a line of a trip card.
class TripCardCatch {
  const TripCardCatch({
    required this.speciesName,
    required this.timeLabel,
    required this.offset,
    this.measureLabel,
    this.isRecord = false,
  });

  final String speciesName;
  final String timeLabel;
  final String? measureLabel;

  /// Position on the trip's time scale, 0–1.
  final double offset;
  final bool isRecord;
}

class TripCardData {
  const TripCardData({
    required this.id,
    required this.dateLabel,
    required this.romanDate,
    required this.durationLabel,
    required this.timeRangeLabel,
    required this.catchCount,
    required this.speciesCount,
    required this.catches,
    required this.speciesTally,
    required this.spanHours,
    required this.elapsedFraction,
    this.moon,
    this.place,
    this.biggestLabel,
    this.topBaitLabel,
    this.photoPath,
    this.photoOptions = const [],
    this.recordCount = 0,
    this.wind,
    this.temperatureLabel,
    this.pressureLabel,
    this.caption,
  });

  final String id;
  final String dateLabel;
  final String romanDate;
  final String? place;
  final String durationLabel;
  final String timeRangeLabel;
  final int catchCount;
  final int speciesCount;

  /// Chronological.
  final List<TripCardCatch> catches;

  /// Species with their catch counts, most caught first.
  final List<(String, int)> speciesTally;

  /// Length of the time board in hours and how much of it the trip used.
  final double spanHours;
  final double elapsedFraction;
  final String? biggestLabel;
  final String? topBaitLabel;
  final String? photoPath;

  /// Every photo of the trip's catches, for the editor to offer.
  final List<String> photoOptions;
  final int recordCount;
  final CardMoon? moon;
  final CardWind? wind;
  final String? temperatureLabel;
  final String? pressureLabel;
  final String? caption;

  TripCardData customized(CardOptions o) => TripCardData(
    id: id,
    dateLabel: dateLabel,
    romanDate: romanDate,
    durationLabel: durationLabel,
    timeRangeLabel: timeRangeLabel,
    catchCount: catchCount,
    speciesCount: speciesCount,
    catches: catches,
    speciesTally: speciesTally,
    spanHours: spanHours,
    elapsedFraction: elapsedFraction,
    moon: o.showWeather ? moon : null,
    place: o.showPlace ? place : null,
    biggestLabel: biggestLabel,
    topBaitLabel: o.showBait ? topBaitLabel : null,
    photoPath: o.photoChosen ? o.photoPath : photoPath,
    photoOptions: photoOptions,
    recordCount: recordCount,
    wind: o.showWeather ? wind : null,
    temperatureLabel: o.showWeather ? temperatureLabel : null,
    pressureLabel: o.showWeather ? pressureLabel : null,
    caption: o._caption,
  );
}
