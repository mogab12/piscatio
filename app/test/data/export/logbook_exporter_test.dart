import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/data/export/logbook_exporter.dart';
import 'package:piscatio/data/repositories/catch_repository.dart';
import 'package:piscatio/data/repositories/settings_repository.dart';
import 'package:piscatio/data/repositories/tackle_repository.dart';
import 'package:piscatio/data/repositories/trip_repository.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/domain/services/units.dart';

import '../../helpers/test_db.dart';

void main() {
  test('exports live data as JSON, never the privacy secret', () async {
    final db = await newSeededDatabase();
    addTearDown(db.close);
    final deps = TestDeps(db);
    final settings = SettingsRepository(db);
    await settings.setUnitSystem(UnitSystem.metric);
    await settings.privacySecret();
    final trips = TripRepository(db, deps.clock, deps.ids);
    final catches = CatchRepository(db, deps.clock, deps.ids);
    final tackle = TackleRepository(db, deps.clock, deps.ids);
    final trip = await trips.createPastTrip(
      startedAt: DateTime.utc(2026, 9, 1, 6),
      endedAt: DateTime.utc(2026, 9, 1, 9),
      timezone: 'America/Sao_Paulo',
      privacy: PrivacyLevel.private,
      location: const GeoPoint(-16.52, -56.41),
      locationName: 'Poço',
    );
    await tackle.addBait('Tuvira', BaitType.natural);
    final kept = await catches.addCatch(
      tripId: trip.id,
      speciesId: 'hoplias-malabaricus',
    );
    final gone = await catches.addCatch(tripId: trip.id);
    await catches.deleteCatch(gone.id);

    final json = jsonDecode(
      await LogbookExporter(db).toJson(DateTime.utc(2026, 9, 2)),
    ) as Map<String, dynamic>;
    expect(json['app'], 'piscatio');
    expect(json['format'], LogbookExporter.formatVersion);
    expect(json['exportedAt'], '2026-09-02T00:00:00.000Z');
    final exportedTrips = json['trips'] as List<dynamic>;
    expect(exportedTrips, hasLength(1));
    final t = exportedTrips.single as Map<String, dynamic>;
    expect(t['locationName'], 'Poço');
    expect(t['startedAt'], startsWith('2026-09-01T06:00:00'));
    expect(t['privacyLevel'], 'private');
    // Deleted catches are left out.
    final exportedCatches = json['catches'] as List<dynamic>;
    expect(exportedCatches.map((c) => (c as Map)['id']), [kept.id]);
    expect(
      (json['baits'] as List<dynamic>).single,
      containsPair('name', 'Tuvira'),
    );
    final exportedSettings = json['settings'] as Map<String, dynamic>;
    expect(exportedSettings['unit_system'], 'metric');
    expect(exportedSettings.containsKey(SettingKeys.privacySecret), isFalse);
  });
}
