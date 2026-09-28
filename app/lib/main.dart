import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/clock.dart';
import 'core/providers.dart';
import 'data/db/app_database.dart';
import 'data/repositories/settings_repository.dart';
import 'data/seed/species_seeder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.open();
  await SpeciesSeeder(
    db,
    SettingsRepository(db),
    const SystemClock(),
  ).apply(await rootBundle.loadString('assets/seed/species.json'));
  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const PiscatioApp(),
    ),
  );
}
