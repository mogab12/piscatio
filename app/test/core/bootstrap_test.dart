import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/bootstrap.dart';
import 'package:piscatio/data/db/app_database.dart';

import '../helpers/test_db.dart';

Widget _ready(AppDatabase _) => const Directionality(
  textDirection: TextDirection.ltr,
  child: Text('ready'),
);

void main() {
  testWidgets('shows the current step, then the app', (tester) async {
    final opened = Completer<AppDatabase>();
    await tester.pumpWidget(
      BootstrapApp(
        open: (onStep) {
          onStep(BootStep.catalog);
          return opened.future;
        },
        app: _ready,
      ),
    );
    await tester.pump();
    expect(find.text('Loading the species…'), findsOneWidget);
    expect(find.text('This is taking longer than usual.'), findsNothing);

    final db = newTestDatabase();
    opened.complete(db);
    await tester.pump();
    await tester.pump();
    expect(find.text('ready'), findsOneWidget);
    await db.close();
  });

  testWidgets('says so when a step is slow', (tester) async {
    await tester.pumpWidget(
      BootstrapApp(
        open: (onStep) {
          onStep(BootStep.database);
          return Completer<AppDatabase>().future;
        },
        app: _ready,
      ),
    );
    await tester.pump(const Duration(seconds: 13));
    expect(find.text('Opening your logbook…'), findsOneWidget);
    expect(find.text('This is taking longer than usual.'), findsOneWidget);
  });

  testWidgets('shows the error and retries', (tester) async {
    var attempts = 0;
    final db = newTestDatabase();
    await tester.pumpWidget(
      BootstrapApp(
        open: (onStep) async {
          attempts++;
          if (attempts == 1) throw StateError('disk is full');
          return db;
        },
        app: _ready,
      ),
    );
    await tester.pump();
    expect(find.text('The app could not open'), findsOneWidget);
    expect(find.textContaining('disk is full'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    expect(attempts, 2);
    expect(find.text('ready'), findsOneWidget);
    await db.close();
  });
}
