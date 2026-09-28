// Fails when UI code contains string literals that should come from the ARB
// files. Heuristic: a literal passed to Text/SelectableText or to a named
// argument that is shown to the user, containing at least one letter outside
// string interpolation. Add `// l10n-ignore` to a line to allow it.
//
// Usage (from app/): dart run tool/check_hardcoded_strings.dart
import 'dart:io';

final _patterns = <RegExp>[
  RegExp(
    r'''\b(?:Text|SelectableText|TextSpan)\(\s*(?:text:\s*)?(['"])(.*?)\1''',
  ),
  RegExp(
    r'''\b(?:tooltip|semanticsLabel|semanticLabel|hintText|labelText|helperText|errorText|counterText|prefixText|suffixText|message|label|title|subtitle|content)\s*:\s*(['"])(.*?)\1''',
  ),
];

void main() {
  final problems = findHardcodedStrings(Directory('lib'));
  if (problems.isEmpty) {
    stdout.writeln('No hardcoded UI strings found.');
    return;
  }
  problems.forEach(stderr.writeln);
  stderr.writeln(
    '\nMove these texts to lib/l10n/app_*.arb '
    '(or mark the line with // l10n-ignore if it is not user-facing).',
  );
  exitCode = 1;
}

List<String> findHardcodedStrings(Directory root) {
  final problems = <String>[];
  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('.g.dart'))
      .where((f) => !f.path.endsWith('.freezed.dart'))
      .where((f) => !f.path.contains('${Platform.pathSeparator}generated'));
  for (final file in files) {
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('l10n-ignore') || line.trimLeft().startsWith('//')) {
        continue;
      }
      for (final pattern in _patterns) {
        for (final m in pattern.allMatches(line)) {
          if (hasVisibleWords(m.group(2)!)) {
            problems.add('${file.path}:${i + 1}: ${line.trim()}');
          }
        }
      }
    }
  }
  return problems;
}

/// True if [literal] still contains letters after removing interpolations.
bool hasVisibleWords(String literal) {
  final stripped = literal
      .replaceAll(RegExp(r'\$\{[^}]*\}'), '')
      .replaceAll(RegExp(r'\$[A-Za-z_][A-Za-z0-9_]*'), '');
  return RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(stripped);
}
