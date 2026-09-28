import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_hardcoded_strings.dart';

void main() {
  test('lib/ has no hardcoded UI strings', () {
    expect(findHardcodedStrings(Directory('lib')), isEmpty);
  });

  test('flags literals with words and ignores interpolation-only ones', () {
    final dir = Directory.systemTemp.createTempSync('hardcoded');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/a.dart').writeAsStringSync('''
Text('Start trip');
Text('\$count');
Text('\${a.b} / \$c');
IconButton(tooltip: "Delete");
Text('Piscatio'); // l10n-ignore
''');
    final problems = findHardcodedStrings(dir);
    expect(problems, hasLength(2));
    expect(problems.first, contains('Start trip'));
    expect(problems.last, contains('Delete'));
  });

  test('hasVisibleWords', () {
    expect(hasVisibleWords(r'${x} kg'), isTrue);
    expect(hasVisibleWords(r'${x} · $y'), isFalse);
    expect(hasVisibleWords('ção'), isTrue);
  });
}
