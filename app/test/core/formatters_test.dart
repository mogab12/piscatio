import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:piscatio/core/formatting/formatters.dart';
import 'package:piscatio/domain/services/moon.dart';
import 'package:piscatio/domain/services/units.dart';
import 'package:piscatio/l10n/generated/app_localizations.dart';

Formatters _f(String lang, UnitSystem units) =>
    Formatters(lookupAppLocalizations(Locale(lang)), units);

void main() {
  setUpAll(() async {
    for (final l in ['pt', 'en', 'es']) {
      await initializeDateFormatting(l);
    }
  });

  test('decimal separator follows the language', () {
    expect(_f('pt', UnitSystem.metric).weight(2350), '2,35 kg');
    expect(_f('en', UnitSystem.metric).weight(2350), '2.35 kg');
    expect(_f('es', UnitSystem.metric).length(525), '52,5 cm');
  });

  test('units are independent from the language', () {
    expect(_f('pt', UnitSystem.imperial).weight(2353), '5 lb 3 oz');
    expect(_f('en', UnitSystem.metric).weight(850), '850 g');
  });

  test('unit symbols are localized', () {
    expect(_f('pt', UnitSystem.imperial).length(521), '20,5 pol');
    expect(_f('es', UnitSystem.imperial).length(521), '20,5 pulg');
    expect(_f('en', UnitSystem.imperial).depth(3048), '10 ft');
    expect(_f('pt', UnitSystem.metric).depth(3200), '3,2 m');
  });

  test('durations and timer', () {
    final pt = _f('pt', UnitSystem.metric);
    expect(pt.duration(const Duration(hours: 3, minutes: 20)), '3 h 20 min');
    expect(pt.duration(const Duration(minutes: 45)), '45 min');
    expect(pt.duration(const Duration(hours: 4)), '4 h');
    expect(
      Formatters.timer(const Duration(hours: 1, minutes: 5, seconds: 9)),
      '1:05:09',
    );
    expect(Formatters.timer(const Duration(seconds: 7)), '0:00:07');
  });

  test('moon and dates are localized', () {
    expect(
      _f('pt', UnitSystem.metric).moonPhase(MoonPhase.fullMoon),
      'Lua cheia',
    );
    expect(
      _f('es', UnitSystem.metric).moonPhase(MoonPhase.newMoon),
      'Luna nueva',
    );
    final d = DateTime.utc(2026, 9, 12, 12);
    expect(_f('en', UnitSystem.metric).date(d), 'Sep 12, 2026');
    expect(_f('pt', UnitSystem.metric).date(d), contains('set'));
  });

  test('parseDecimal accepts comma or dot and rejects garbage', () {
    expect(parseDecimal('2,5'), 2.5);
    expect(parseDecimal(' 2.5 '), 2.5);
    expect(parseDecimal('12'), 12);
    expect(parseDecimal(''), isNull);
    expect(parseDecimal('abc'), isNull);
    expect(parseDecimal('-3'), isNull);
  });
}
