import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:piscatio/core/formatting/formatters.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/domain/models/species.dart';
import 'package:piscatio/domain/models/tackle.dart';
import 'package:piscatio/domain/models/trip.dart';
import 'package:piscatio/domain/models/weather.dart';
import 'package:piscatio/domain/services/moon.dart';
import 'package:piscatio/domain/services/ruler_scale.dart';
import 'package:piscatio/domain/services/units.dart';
import 'package:piscatio/features/cards/application/card_builder.dart';
import 'package:piscatio/l10n/generated/app_localizations_pt.dart';

final _t0 = DateTime.utc(2026, 9, 12, 9);
final _f = Formatters(AppLocalizationsPt(), UnitSystem.metric);

const _dourado = Species(
  id: 'salminus-brasiliensis',
  scientificName: 'Salminus brasiliensis',
  names: [SpeciesName(lang: 'pt', name: 'Dourado', isPrimary: true)],
);

Trip _trip({PrivacyLevel privacy = PrivacyLevel.exact, DateTime? endedAt}) =>
    Trip(
      id: 'trip-1',
      startedAt: _t0,
      endedAt: endedAt ?? _t0.add(const Duration(hours: 3, minutes: 20)),
      timezone: 'UTC',
      location: const GeoPoint(-16.52, -56.41),
      locationName: 'Poço do Dourado',
      locationRegion: 'Cuiabá, MT',
      privacyLevel: privacy,
      moonPhase: MoonPhase.waxingGibbous,
      moonIllumination: 0.7,
      createdAt: _t0,
      updatedAt: _t0,
    );

Catch _c(
  String id, {
  String tripId = 'trip-1',
  String? species = 'salminus-brasiliensis',
  Duration after = Duration.zero,
  int? g,
  int? mm,
  String? baitId,
}) => Catch(
  id: id,
  tripId: tripId,
  speciesId: species,
  caughtAt: _t0.add(after),
  weightGrams: g,
  lengthMillimeters: mm,
  baitId: baitId,
  createdAt: _t0,
  updatedAt: _t0,
);

void main() {
  setUpAll(() => initializeDateFormatting('pt'));

  group('buildCatchCard', () {
    test('logbook number, length board, record against the earlier best', () {
      final older = _c(
        'a',
        tripId: 'old',
        after: const Duration(days: -30),
        mm: 630,
      );
      final item = _c('b', after: const Duration(hours: 1), mm: 720, g: 4200);
      final card = buildCatchCard(
        item: item,
        trip: _trip(),
        allCatches: [item, older],
        species: _dourado,
        f: _f,
        lang: 'pt',
        bait: const Bait(id: 'x', name: 'Tuvira', type: BaitType.natural),
      );
      expect(card.catchNumber, 2);
      expect(card.speciesName, 'Dourado');
      expect(card.scientificName, 'Salminus brasiliensis');
      expect(card.ruler.unit, RulerUnit.centimeter);
      expect(card.ruler.value, 72);
      expect(card.ruler.previous, 63);
      expect(card.rulerUnit, 'cm');
      expect(card.headline.single.value, '72');
      expect(card.headline.single.unit, 'cm');
      expect(card.record!.isFirst, isFalse);
      expect(card.record!.improvement, '+14%');
      expect(card.previousRecordLabel, '63 cm');
      expect(card.weightLabel, '4,2 kg');
      expect(card.baitLabel, 'Tuvira');
      expect(card.romanDate, '12.IX.2026');
      // The trip is in the southern hemisphere: only that bit is kept.
      expect(card.moon.southern, isTrue);
    });

    test('first of the species; weight board when there is no length', () {
      final item = _c('a', g: 900);
      final card = buildCatchCard(
        item: item,
        trip: _trip(),
        allCatches: [item],
        species: _dourado,
        f: _f,
        lang: 'pt',
      );
      expect(card.record!.isFirst, isTrue);
      expect(card.ruler.unit, RulerUnit.kilogram);
      expect(card.headline.single.unit, 'g');
      expect(card.previousRecordLabel, isNull);
    });

    test('no measure: the board shows the time of day', () {
      final item = _c('a', species: null);
      final card = buildCatchCard(
        item: item,
        trip: _trip(),
        allCatches: [item],
        species: null,
        f: _f,
        lang: 'pt',
      );
      expect(card.ruler.unit, RulerUnit.hour);
      expect(card.headline, isEmpty);
      expect(card.speciesName, 'Espécie não identificada');
      expect(card.record, isNull);
    });

    test('place follows the trip privacy; never coordinates', () {
      final item = _c('a', mm: 400);
      String? placeFor(PrivacyLevel level) => buildCatchCard(
        item: item,
        trip: _trip(privacy: level),
        allCatches: [item],
        species: _dourado,
        f: _f,
        lang: 'pt',
      ).place;
      expect(placeFor(PrivacyLevel.private), isNull);
      expect(placeFor(PrivacyLevel.friends), isNull);
      expect(placeFor(PrivacyLevel.approximate), 'Cuiabá, MT');
      expect(placeFor(PrivacyLevel.exact), 'Poço do Dourado');
      final hidden = buildCatchCard(
        item: item,
        trip: _trip(),
        allCatches: [item],
        species: _dourado,
        f: _f,
        lang: 'pt',
      ).withoutPlace();
      expect(hidden.place, isNull);
      expect(hidden.speciesName, 'Dourado');
    });

    test('weather shows only once published', () {
      final item = _c('a', mm: 400);
      final pending = buildCatchCard(
        item: item,
        trip: _trip(),
        allCatches: [item],
        species: _dourado,
        f: _f,
        lang: 'pt',
        weather: const TripWeather(
          tripId: 'trip-1',
          status: WeatherStatus.pending,
        ),
      );
      expect(pending.wind, isNull);
      expect(pending.temperatureLabel, isNull);
      final ok = buildCatchCard(
        item: item,
        trip: _trip(),
        allCatches: [item],
        species: _dourado,
        f: _f,
        lang: 'pt',
        weather: TripWeather(
          tripId: 'trip-1',
          status: WeatherStatus.ok,
          temperatureC: 24,
          pressureHpa: 1012,
          windSpeedKmh: 9,
          windDirectionDeg: 135,
          fetchedAt: _t0,
        ),
      );
      expect(ok.wind!.label, '9 km/h SE');
      expect(ok.temperatureLabel, '24 °C');
      expect(ok.pressureLabel, '1.012 hPa');
    });
  });

  group('buildTripCard', () {
    test('counts, tally, time offsets, records and the biggest', () {
      final older = _c(
        'z',
        tripId: 'old',
        after: const Duration(days: -30),
        g: 2000,
      );
      final catches = [
        _c(
          'a',
          species: 'hoplias-malabaricus',
          after: const Duration(minutes: 30),
        ),
        _c('b', after: const Duration(hours: 1), g: 4200, baitId: 'x'),
        _c(
          'c',
          species: 'hoplias-malabaricus',
          after: const Duration(hours: 2),
        ),
      ];
      final card = buildTripCard(
        trip: _trip(privacy: PrivacyLevel.approximate),
        catches: catches,
        allCatches: [...catches, older],
        speciesById: {'salminus-brasiliensis': _dourado},
        f: _f,
        lang: 'pt',
        now: _t0.add(const Duration(days: 1)),
        baitsById: {
          'x': const Bait(id: 'x', name: 'Tuvira', type: BaitType.natural),
        },
      );
      expect(card.catchCount, 3);
      expect(card.speciesCount, 2);
      expect(card.place, 'Cuiabá, MT');
      // Unknown species (not in the map) still get a readable name.
      expect(card.speciesTally.first.$2, 2);
      expect(card.catches.map((c) => c.timeLabel), ['09:30', '10:00', '11:00']);
      // 3h20 trip: 3h30 board, catches placed along it.
      expect(card.spanHours, 3.5);
      expect(card.catches[1].offset, closeTo(1 / 3.5, 1e-9));
      expect(card.elapsedFraction, closeTo(200 / 210, 1e-9));
      expect(card.catches[1].isRecord, isTrue);
      expect(card.recordCount, 1);
      expect(card.biggestLabel, 'Dourado, 4,2 kg');
      expect(card.topBaitLabel, 'Tuvira');
      expect(card.timeRangeLabel, 'Das 09:00 às 12:20');
    });

    test('board span is at least an hour, in half hours', () {
      expect(tripSpanHours(Duration.zero), 1);
      expect(tripSpanHours(const Duration(minutes: 55)), 1.5);
      expect(tripSpanHours(const Duration(hours: 4, minutes: 12)), 4.5);
    });
  });
}
