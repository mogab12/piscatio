import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/theme/app_theme.dart';
import 'package:piscatio/features/cards/presentation/card_editor_screen.dart';

import '../features/summary/trip_summary_test.dart' show seedSummaryTrip;
import '../helpers/pump_app.dart';
import '../helpers/screenshots.dart';

void main() {
  setUpAll(loadRealFonts);

  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    testWidgets('card editor details, $name', (tester) async {
      usePhoneSurface(tester);
      final app = await TestApp.start(tester);
      final tripId = await seedSummaryTrip(app, tester);
      await app.pumpScreen(
        tester,
        CardEditorScreen(subject: CardSubject.trip, id: tripId),
        theme: theme,
      );
      await tester.tap(find.text('Detalhes'));
      await app.settle(tester);
      await saveScreenshot(tester, 'editor_details_$name');
      await tester.tap(find.text('Estilo'));
      await app.settle(tester);
      await saveScreenshot(tester, 'editor_style_$name');
      await app.dispose(tester);
    }, skip: !screenshotsEnabled);
  }
}
