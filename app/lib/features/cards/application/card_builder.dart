import 'dart:math' as math;
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/background.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/providers.dart';
import '../../../data/media/photo_storage.dart';
import '../../../domain/models/catch.dart';
import '../../../domain/models/species.dart';
import '../../../domain/models/tackle.dart';
import '../../../domain/models/trip.dart';
import '../../../domain/models/weather.dart';
import '../../../domain/services/card_privacy.dart';
import '../../../domain/services/map_sketch.dart';
import '../../../domain/services/moon.dart';
import '../../../domain/services/records.dart';
import '../../../domain/services/roman_date.dart';
import '../../../domain/services/ruler_scale.dart';
import '../../../domain/services/trip_summary.dart';
import '../../../domain/services/units.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../common/species_label.dart';
import '../../settings/application/preferences.dart';
import 'card_data.dart';
import 'card_map.dart';

String? _photo(String? root, String? relative) =>
    root == null || relative == null ? null : p.join(root, relative);

/// The record the card features: the measure on the board first (length
/// when there is one), preferring a mark that beat an earlier value.
CardRecord? _record(CatchRecordStatus s, Formatters f, {required bool length}) {
  if (s.firstOfSpecies) return const CardRecord.first();
  final marks = [
    ?(length ? s.length : s.weight),
    ?(length ? s.weight : s.length),
  ];
  if (marks.isEmpty) return null;
  final mark =
      marks.firstWhereOrNull((m) => m.improvement != null) ?? marks.first;
  return CardRecord.record(
    improvement: mark.improvement == null
        ? null
        : f.percentGain(mark.improvement!),
  );
}

CardWind? _wind(Formatters f, double? speed, double? from) =>
    speed == null || from == null
    ? null
    : CardWind(
        fromDegrees: from,
        label: '${f.windSpeed(speed)} ${f.compass(from)}',
      );

/// A round distance about a third of the map's half-width, in the user's
/// units.
CardMapScale? mapScaleFor(MapSketch? map, Formatters f) {
  if (map == null) return null;
  final target = map.metersPerUnit * 0.4;
  final List<CardMapScale> steps;
  if (f.units == UnitSystem.imperial) {
    const mile = 1609.344;
    steps = [
      for (final miles in [0.1, 0.25, 0.5, 1.0, 2.0, 5.0, 10.0])
        CardMapScale(
          miles * mile,
          '${f.number(miles, maxFractionDigits: 2)} ${f.l10n.unitMile}',
        ),
    ];
  } else {
    steps = [
      for (final meters in [
        50.0,
        100.0,
        200.0,
        500.0,
        1000.0,
        2000.0,
        5000.0,
        10000.0,
      ])
        CardMapScale(
          meters,
          meters < 1000
              ? '${f.number(meters)} ${f.l10n.unitMeter}'
              : '${f.number(meters / 1000)} ${f.l10n.unitKilometer}',
        ),
    ];
  }
  final chosen = steps.lastWhere(
    (s) => s.meters <= target,
    orElse: () => steps[1],
  );
  return CardMapScale(chosen.meters, chosen.label, steps: steps);
}

String rulerUnitLabel(RulerUnit unit, Formatters f) => switch (unit) {
  RulerUnit.centimeter => f.unitSymbol(DisplayUnit.centimeter),
  RulerUnit.inch => f.unitSymbol(DisplayUnit.inch),
  RulerUnit.kilogram => f.unitSymbol(DisplayUnit.kilogram),
  RulerUnit.pound => f.unitSymbol(DisplayUnit.pound),
  RulerUnit.hour => f.l10n.cardHoursUnit,
};

/// Builds a catch card from domain data. Pure: no I/O, easy to test.
CatchCardData buildCatchCard({
  required Catch item,
  required Trip trip,
  required List<Catch> allCatches,
  required Species? species,
  required Formatters f,
  required String lang,
  TripWeather? weather,
  Bait? bait,
  String? photoRoot,
  MapSketch? map,
}) {
  final l10n = f.l10n;
  final status = recordStatus(item, allCatches);
  final ordered = allCatches.sorted((a, b) {
    final t = a.caughtAt.compareTo(b.caughtAt);
    return t != 0 ? t : a.id.compareTo(b.id);
  });
  final number = ordered.indexWhere((c) => c.id == item.id) + 1;

  final RulerScale ruler;
  String? previous;
  var headline = const <Quantity>[];
  if (item.lengthMillimeters != null) {
    final prev = status.length?.previous;
    ruler = lengthScale(item.lengthMillimeters!, f.units, previousMm: prev);
    previous = prev == null ? null : f.length(prev);
    headline = [lengthQuantity(item.lengthMillimeters!, f.units)];
  } else if (item.weightGrams != null) {
    final prev = status.weight?.previous;
    ruler = weightScale(item.weightGrams!, f.units, previousGrams: prev);
    previous = prev == null ? null : f.weight(prev);
    headline = weightParts(item.weightGrams!, f.units);
  } else {
    ruler = dayScale(item.caughtAt.toLocal());
  }

  final moon = moonAt(item.caughtAt);
  final w = (weather?.hasData ?? false) ? weather : null;
  final hour = w?.at(item.caughtAt);
  final temp = hour?.temperatureC ?? w?.temperatureC;
  final pressure = hour?.pressureHpa ?? w?.pressureHpa;

  return CatchCardData(
    id: item.id,
    speciesName: species?.displayName(lang) ?? l10n.speciesUnknown,
    scientificName: scientificNameOf(species),
    dateLabel: f.date(item.caughtAt),
    timeLabel: f.time(item.caughtAt),
    romanDate: romanDate(item.caughtAt.toLocal()),
    catchNumber: math.max(number, 1),
    place: cardPlace(
      trip.privacyLevel,
      name: trip.locationName,
      region: trip.locationRegion,
    ),
    lengthLabel: item.lengthMillimeters == null
        ? null
        : f.length(item.lengthMillimeters!),
    weightLabel: item.weightGrams == null ? null : f.weight(item.weightGrams!),
    baitLabel: bait?.name,
    released: item.released,
    photoPath: _photo(photoRoot, item.coverPhoto?.relativePath),
    photoOptions: [
      for (final p in item.photos) ?_photo(photoRoot, p.relativePath),
    ],
    ruler: ruler,
    rulerUnit: rulerUnitLabel(ruler.unit, f),
    headline: [
      for (final q in headline)
        CardQuantity(f.quantityValue(q), f.unitSymbol(q.unit)),
    ],
    record: _record(status, f, length: item.lengthMillimeters != null),
    previousRecordLabel: status.isRecord ? previous : null,
    moon: CardMoon(
      illumination: moon.illumination,
      waxing: moon.isWaxing,
      label: f.moonPhase(moon.phase),
      southern: (trip.location?.latitude ?? 1) < 0,
    ),
    wind: w == null
        ? null
        : _wind(
            f,
            hour?.windSpeedKmh ?? w.windSpeedKmh,
            hour?.windDirectionDeg ?? w.windDirectionDeg,
          ),
    temperatureLabel: temp == null ? null : f.temperature(temp),
    pressureLabel: pressure == null ? null : f.pressure(pressure),
    map: map,
    mapScale: mapScaleFor(map, f),
  );
}

/// Board length for a trip: at least an hour, then the trip plus a little
/// room, in half hours (same rule as the active trip's time ruler).
double tripSpanHours(Duration elapsed) {
  final minutes = math.max(60, elapsed.inMinutes + 10);
  return (minutes / 30).ceil() * 30 / 60;
}

TripCardData buildTripCard({
  required Trip trip,
  required List<Catch> catches,
  required List<Catch> allCatches,
  required Map<String, Species> speciesById,
  required Formatters f,
  required String lang,
  required DateTime now,
  TripWeather? weather,
  Map<String, Bait> baitsById = const {},
  String? photoRoot,
  MapSketch? map,
}) {
  final l10n = f.l10n;
  String name(String? id) =>
      (id == null ? null : speciesById[id]?.displayName(lang)) ??
      l10n.speciesUnknown;
  final summary = summarizeTrip(trip, catches, now);
  final span = tripSpanHours(summary.duration);
  final chronological = catches.sortedBy((c) => c.caughtAt);
  final records = {
    for (final c in chronological) c.id: recordStatus(c, allCatches).isRecord,
  };

  final tally = <String?, int>{};
  for (final c in chronological) {
    tally[c.speciesId] = (tally[c.speciesId] ?? 0) + 1;
  }
  final species = tally.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final biggest = summary.biggest;
  final withPhoto = biggest?.coverPhoto != null
      ? biggest
      : chronological.where((c) => c.coverPhoto != null).firstOrNull;
  final moon = moonAt(trip.startedAt);
  final w = (weather?.hasData ?? false) ? weather : null;

  return TripCardData(
    id: trip.id,
    dateLabel: f.date(trip.startedAt),
    romanDate: romanDate(trip.startedAt.toLocal()),
    place: cardPlace(
      trip.privacyLevel,
      name: trip.locationName,
      region: trip.locationRegion,
    ),
    durationLabel: f.duration(summary.duration),
    timeRangeLabel: trip.endedAt == null
        ? l10n.activeTripStartedAt(f.time(trip.startedAt))
        : l10n.tripTimeRange(f.time(trip.startedAt), f.time(trip.endedAt!)),
    catchCount: summary.catchCount,
    speciesCount: summary.speciesCount,
    catches: [
      for (final c in chronological)
        TripCardCatch(
          speciesName: name(c.speciesId),
          timeLabel: f.time(c.caughtAt),
          measureLabel: c.weightGrams != null
              ? f.weight(c.weightGrams!)
              : c.lengthMillimeters != null
              ? f.length(c.lengthMillimeters!)
              : null,
          offset:
              (c.caughtAt.difference(trip.startedAt).inSeconds / (span * 3600))
                  .clamp(0.0, 1.0),
          isRecord: records[c.id] ?? false,
        ),
    ],
    speciesTally: [for (final e in species) (name(e.key), e.value)],
    spanHours: span,
    elapsedFraction: (summary.duration.inSeconds / (span * 3600)).clamp(
      0.0,
      1.0,
    ),
    biggestLabel: biggest == null
        ? null
        : l10n.cardBiggestValue(
            name(biggest.speciesId),
            biggest.weightGrams != null
                ? f.weight(biggest.weightGrams!)
                : f.length(biggest.lengthMillimeters!),
          ),
    topBaitLabel: summary.topBaitId == null
        ? null
        : baitsById[summary.topBaitId]?.name,
    photoPath: _photo(photoRoot, withPhoto?.coverPhoto?.relativePath),
    photoOptions: [
      for (final c in chronological)
        for (final p in c.photos) ?_photo(photoRoot, p.relativePath),
    ],
    recordCount: records.values.where((r) => r).length,
    moon: CardMoon(
      illumination: trip.moonIllumination,
      waxing: moon.isWaxing,
      label: f.moonPhase(trip.moonPhase),
      southern: (trip.location?.latitude ?? 1) < 0,
    ),
    wind: w == null ? null : _wind(f, w.windSpeedKmh, w.windDirectionDeg),
    temperatureLabel: w == null ? null : f.temperature(w.temperatureC!),
    pressureLabel: w?.pressureHpa == null ? null : f.pressure(w!.pressureHpa!),
    map: map,
    mapScale: mapScaleFor(map, f),
  );
}

Formatters _formatters(Ref ref) => Formatters(
  lookupAppLocalizations(Locale(ref.watch(effectiveLanguageProvider))),
  ref.watch(unitSystemProvider),
);

/// Card data for a catch, or null while its dependencies load.
final catchCardDataProvider = Provider.family<CatchCardData?, String>((
  ref,
  catchId,
) {
  final item = ref.watch(catchProvider(catchId)).value;
  if (item == null) return null;
  final trip = ref.watch(tripProvider(item.tripId)).value;
  final all = ref.watch(allCatchesProvider).value;
  final root = ref.watch(photoRootProvider).value;
  if (trip == null || all == null || root == null) return null;
  final baits = ref.watch(baitsProvider).value ?? const [];
  return buildCatchCard(
    item: item,
    trip: trip,
    allCatches: all,
    species: item.speciesId == null
        ? null
        : ref.watch(speciesByIdProvider)[item.speciesId],
    f: _formatters(ref),
    lang: ref.watch(effectiveLanguageProvider),
    weather: ref.watch(tripWeatherProvider(trip.id)).value,
    bait: baits.where((b) => b.id == item.baitId).firstOrNull,
    photoRoot: root.path,
    map: ref.watch(tripMapProvider(trip.id)).sketch,
  );
});

final tripCardDataProvider = Provider.family<TripCardData?, String>((
  ref,
  tripId,
) {
  final trip = ref.watch(tripProvider(tripId)).value;
  final catches = ref.watch(tripCatchesProvider(tripId)).value;
  final all = ref.watch(allCatchesProvider).value;
  final root = ref.watch(photoRootProvider).value;
  if (trip == null || catches == null || all == null || root == null) {
    return null;
  }
  final baits = ref.watch(baitsProvider).value ?? const [];
  return buildTripCard(
    trip: trip,
    catches: catches,
    allCatches: all,
    speciesById: ref.watch(speciesByIdProvider),
    f: _formatters(ref),
    lang: ref.watch(effectiveLanguageProvider),
    now: ref.watch(clockProvider).now(),
    weather: ref.watch(tripWeatherProvider(tripId)).value,
    baitsById: {for (final b in baits) b.id: b},
    photoRoot: root.path,
    map: ref.watch(tripMapProvider(trip.id)).sketch,
  );
});
