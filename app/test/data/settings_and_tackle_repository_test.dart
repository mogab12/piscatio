import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/data/db/app_database.dart';
import 'package:piscatio/data/repositories/settings_repository.dart';
import 'package:piscatio/data/repositories/species_repository.dart';
import 'package:piscatio/data/repositories/tackle_repository.dart';
import 'package:piscatio/data/repositories/trip_repository.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/services/units.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;

  setUp(() {
    db = newTestDatabase();
    settings = SettingsRepository(db, random: Random(1));
  });
  tearDown(() => db.close());

  test('defaults: follow device, private, onboarding pending', () async {
    final s = await settings.read();
    expect(s.languageCode, isNull);
    expect(s.unitSystem, isNull);
    expect(s.defaultPrivacy, PrivacyLevel.private);
    expect(s.onboardingCompleted, isFalse);
  });

  test('stores language, units, privacy and onboarding', () async {
    await settings.setLanguage('es');
    await settings.setUnitSystem(UnitSystem.imperial);
    await settings.setDefaultPrivacy(PrivacyLevel.approximate);
    await settings.completeOnboarding();
    final s = await settings.read();
    expect(s.languageCode, 'es');
    expect(s.unitSystem, UnitSystem.imperial);
    expect(s.defaultPrivacy, PrivacyLevel.approximate);
    expect(s.onboardingCompleted, isTrue);

    await settings.setLanguage(null);
    expect((await settings.read()).languageCode, isNull);
  });

  test('privacy secret is created once and then reused', () async {
    final a = await settings.privacySecret();
    final b = await settings.privacySecret();
    expect(a, hasLength(32));
    expect(b, a);
  });

  test('tackle lists are sorted and ignore blank names', () async {
    final deps = TestDeps(db);
    final tackle = TackleRepository(db, deps.clock, deps.ids);
    await tackle.addBait('minhoca', BaitType.natural);
    await tackle.addBait('Jig 10 g', BaitType.artificial);
    await tackle.addGear('Carretilha perfil baixo', GearType.reel);
    expect((await tackle.watchBaits().first).map((b) => b.name), [
      'Jig 10 g',
      'minhoca',
    ]);
    expect(await tackle.watchGear().first, hasLength(1));
    expect(() => tackle.addBait('  ', BaitType.other), throwsArgumentError);
  });

  test('wipeUserData removes user records but keeps the catalog', () async {
    final seeded = await newSeededDatabase();
    addTearDown(seeded.close);
    final deps = TestDeps(seeded);
    await TripRepository(
      seeded,
      deps.clock,
      deps.ids,
    ).startTrip(timezone: 'UTC', privacy: PrivacyLevel.private);
    final species = SpeciesRepository(seeded, deps.clock, deps.ids);
    await species.addCustomSpecies('Peixe misterioso', lang: 'pt');
    final before = (await species.all()).length;

    await seeded.wipeUserData();

    expect(await seeded.select(seeded.trips).get(), isEmpty);
    expect(await seeded.select(seeded.settings).get(), isEmpty);
    expect((await species.all()).length, before - 1);
  });
}
