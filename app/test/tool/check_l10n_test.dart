import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_l10n.dart';

void main() {
  test('the real ARB files are complete in en, pt and es', () {
    expect(checkArbDirectory(Directory('lib/l10n')), isEmpty);
  });

  group('checkArbDirectory', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('arb'));
    tearDown(() => dir.deleteSync(recursive: true));

    void write(String locale, String json) =>
        File('${dir.path}/app_$locale.arb').writeAsStringSync(json);

    test('reports a key missing in one locale', () {
      write(
        'en',
        '{"@@locale":"en","a":"A","@a":{"description":"d"},'
            '"b":"B","@b":{"description":"d"}}',
      );
      write('pt', '{"@@locale":"pt","a":"A","b":"B"}');
      write('es', '{"@@locale":"es","a":"A"}');
      expect(checkArbDirectory(dir), ['es: missing key "b"']);
    });

    test('reports placeholder mismatch and empty values', () {
      write(
        'en',
        '{"@@locale":"en","hi":"Hi {name}",'
            '"@hi":{"description":"d","placeholders":{"name":{}}}}',
      );
      write('pt', '{"@@locale":"pt","hi":"Oi {nome}"}');
      write('es', '{"@@locale":"es","hi":" "}');
      expect(checkArbDirectory(dir), hasLength(2));
    });

    test('reports template keys without description', () {
      write('en', '{"@@locale":"en","a":"A"}');
      write('pt', '{"@@locale":"pt","a":"A"}');
      write('es', '{"@@locale":"es","a":"A"}');
      expect(checkArbDirectory(dir), ['en: "a" has no @a.description']);
    });
  });

  test('placeholdersOf finds plural and nested arguments', () {
    expect(
      placeholdersOf(
        '{count, plural, =1{One fish in {place}} other{{count} fish}}',
      ),
      {'count', 'place'},
    );
  });
}
