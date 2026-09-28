import 'dart:ui';

import '../../../domain/services/ruler_scale.dart';

enum CardStyle { board, chart, tag }

enum CardFormat {
  story(Size(1080, 1920)),
  square(Size(1080, 1080));

  const CardFormat(this.size);

  final Size size;
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
    required this.moon,
    this.headline = const [],
    this.scientificName,
    this.place,
    this.lengthLabel,
    this.weightLabel,
    this.baitLabel,
    this.released,
    this.photoPath,
    this.record,
    this.previousRecordLabel,
    this.wind,
    this.temperatureLabel,
    this.pressureLabel,
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
  final RulerScale ruler;

  /// Unit printed at the end of the board ("cm", "lb", "h").
  final String rulerUnit;

  /// The featured measure (length, else weight), split for styling; empty
  /// when the catch was not measured.
  final List<CardQuantity> headline;
  final CardRecord? record;

  /// "46 cm": the best before this catch, for the board's record mark.
  final String? previousRecordLabel;
  final CardMoon moon;
  final CardWind? wind;
  final String? temperatureLabel;
  final String? pressureLabel;

  CatchCardData withoutPlace() => CatchCardData(
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
    moon: moon,
    lengthLabel: lengthLabel,
    weightLabel: weightLabel,
    baitLabel: baitLabel,
    released: released,
    photoPath: photoPath,
    record: record,
    previousRecordLabel: previousRecordLabel,
    wind: wind,
    temperatureLabel: temperatureLabel,
    pressureLabel: pressureLabel,
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
    required this.moon,
    this.place,
    this.biggestLabel,
    this.topBaitLabel,
    this.photoPath,
    this.recordCount = 0,
    this.wind,
    this.temperatureLabel,
    this.pressureLabel,
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
  final int recordCount;
  final CardMoon moon;
  final CardWind? wind;
  final String? temperatureLabel;
  final String? pressureLabel;

  TripCardData withoutPlace() => TripCardData(
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
    moon: moon,
    biggestLabel: biggestLabel,
    topBaitLabel: topBaitLabel,
    photoPath: photoPath,
    recordCount: recordCount,
    wind: wind,
    temperatureLabel: temperatureLabel,
    pressureLabel: pressureLabel,
  );
}
