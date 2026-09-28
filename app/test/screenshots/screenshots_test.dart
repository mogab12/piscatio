import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/providers.dart';

import '../helpers/pump_app.dart';
import '../helpers/screenshots.dart';

void main() {
  setUpAll(loadRealFonts);

  testWidgets('onboarding', (tester) async {
    usePhoneSurface(tester);
    final app = await TestApp.start(tester);
    await app.pumpApp(tester);
    await saveScreenshot(tester, 'onboarding_1_language');
    await tester.tap(find.text('Continuar'));
    await app.settle(tester);
    await saveScreenshot(tester, 'onboarding_2_units');
    await tester.tap(find.text('Continuar'));
    await app.settle(tester);
    await saveScreenshot(tester, 'onboarding_3_location');
    await app.dispose(tester);
  }, skip: !screenshotsEnabled);

  testWidgets('settings', (tester) async {
    usePhoneSurface(tester);
    final app = await TestApp.start(tester);
    await app.run(
      tester,
      () => app.read(settingsRepositoryProvider).completeOnboarding(),
    );
    await app.pumpApp(tester);
    await tester.tap(find.text('Ajustes'));
    await app.settle(tester);
    await saveScreenshot(tester, 'settings');
    await tester.tap(find.text('Privacidade padrão do local'));
    await app.settle(tester);
    await saveScreenshot(tester, 'settings_privacy_sheet');
    await app.dispose(tester);
  }, skip: !screenshotsEnabled);
}
