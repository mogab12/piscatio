import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/locale.dart';

void main() {
  test('uses the explicit choice first', () {
    expect(
      resolveAppLocale(
        chosenLanguage: 'es',
        deviceLocales: const [Locale('pt', 'BR')],
      ),
      const Locale('es'),
    );
  });

  test('follows the first supported device language', () {
    expect(
      resolveAppLocale(
        chosenLanguage: null,
        deviceLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      ),
      const Locale('pt'),
    );
    expect(
      resolveAppLocale(
        chosenLanguage: null,
        deviceLocales: const [Locale('de', 'DE'), Locale('es', 'MX')],
      ),
      const Locale('es'),
    );
  });

  test('falls back to English for unsupported languages', () {
    expect(
      resolveAppLocale(
        chosenLanguage: null,
        deviceLocales: const [Locale('fr', 'FR'), Locale('ja')],
      ),
      const Locale('en'),
    );
    expect(
      resolveAppLocale(chosenLanguage: 'it', deviceLocales: const []),
      const Locale('en'),
    );
  });
}
