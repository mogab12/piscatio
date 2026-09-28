import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/features/summary/presentation/trip_summary_screen.dart';

import '../../helpers/pump_app.dart';

/// A finished trip with a length record for traíra (+20% over an older
/// trip) and a first dourado. Returns the new trip's id.
Future<String> seedSummaryTrip(TestApp app, WidgetTester tester) =>
    app.run(tester, () async {
      final trips = app.read(tripRepositoryProvider);
      final catches = app.read(catchRepositoryProvider);
      final now = app.clock.now();
      Future<void> add(String trip, String species, DateTime at, int mm) async {
        final c = await catches.addCatch(
          tripId: trip,
          speciesId: species,
          caughtAt: at,
        );
        await catches.updateDetails(
          c.id,
          CatchDetails(speciesId: species, lengthMillimeters: mm),
        );
      }

      final old = await trips.createPastTrip(
        startedAt: now.subtract(const Duration(days: 20)),
        endedAt: now.subtract(const Duration(days: 20, hours: -2)),
        timezone: 'UTC',
        privacy: PrivacyLevel.private,
      );
      await add(
        old.id,
        'hoplias-malabaricus',
        old.startedAt.add(const Duration(minutes: 30)),
        400,
      );
      final start = now.subtract(const Duration(hours: 5));
      final trip = await trips.createPastTrip(
        startedAt: start,
        endedAt: start.add(const Duration(hours: 4, minutes: 12)),
        timezone: 'UTC',
        privacy: PrivacyLevel.private,
      );
      await add(
        trip.id,
        'hoplias-malabaricus',
        start.add(const Duration(hours: 1)),
        480,
      );
      await add(
        trip.id,
        'salminus-brasiliensis',
        start.add(const Duration(hours: 2)),
        720,
      );
      return trip.id;
    });

void main() {
  testWidgets('summary shows totals, records and the card action', (
    tester,
  ) async {
    final app = await TestApp.start(tester);
    final tripId = await seedSummaryTrip(app, tester);
    await app.pumpScreen(tester, TripSummaryScreen(tripId: tripId));

    expect(find.text('Pescaria finalizada'), findsOneWidget);
    expect(find.text('4 h 12 min'), findsOneWidget);
    expect(find.text('capturas'), findsOneWidget);
    expect(find.text('espécies'), findsOneWidget);
    expect(find.text('Recordes'), findsOneWidget);
    expect(find.text('Recorde pessoal, +20%'), findsOneWidget);
    expect(find.text('Traíra, 48 cm'), findsOneWidget);
    expect(find.text('Primeira da espécie'), findsOneWidget);
    expect(find.text('Criar card'), findsOneWidget);
    await app.dispose(tester);
  });
}
