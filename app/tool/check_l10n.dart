// Fails when the pt/en/es ARB files diverge: missing or extra keys, empty
// translations, missing @descriptions or mismatched placeholders.
//
// Usage (from app/): dart run tool/check_l10n.dart
import 'dart:convert';
import 'dart:io';

const _dir = 'lib/l10n';
const _template = 'app_en.arb';
const _locales = ['en', 'pt', 'es'];

void main() {
  final errors = checkArbDirectory(Directory(_dir));
  if (errors.isEmpty) {
    stdout.writeln('l10n OK: ${_locales.join(', ')} are complete.');
    return;
  }
  for (final e in errors) {
    stderr.writeln('l10n: $e');
  }
  exitCode = 1;
}

/// Returns a list of human-readable problems found in [dir].
List<String> checkArbDirectory(Directory dir) {
  final errors = <String>[];
  final files = <String, Map<String, dynamic>>{};
  for (final locale in _locales) {
    final file = File('${dir.path}/app_$locale.arb');
    if (!file.existsSync()) {
      errors.add('missing ${file.path}');
      continue;
    }
    files[locale] = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
  final template = files['en'];
  if (template == null) return errors..add('missing template $_template');

  final templateKeys = _messageKeys(template);
  for (final key in templateKeys) {
    final meta = template['@$key'];
    if (meta is! Map || (meta['description'] as String? ?? '').trim().isEmpty) {
      errors.add('en: "$key" has no @$key.description');
    }
  }

  for (final entry in files.entries) {
    final locale = entry.key;
    final arb = entry.value;
    if (arb['@@locale'] != locale) {
      errors.add('$locale: @@locale must be "$locale"');
    }
    final keys = _messageKeys(arb);
    for (final missing in templateKeys.difference(keys)) {
      errors.add('$locale: missing key "$missing"');
    }
    for (final extra in keys.difference(templateKeys)) {
      errors.add('$locale: key "$extra" does not exist in the template');
    }
    for (final key in keys.intersection(templateKeys)) {
      final value = arb[key];
      if (value is! String || value.trim().isEmpty) {
        errors.add('$locale: "$key" is empty');
        continue;
      }
      final expected = placeholdersOf(template[key] as String);
      final actual = placeholdersOf(value);
      if (expected.length != actual.length || !expected.containsAll(actual)) {
        errors.add(
          '$locale: "$key" placeholders $actual differ from template $expected',
        );
      }
    }
  }
  return errors;
}

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

/// Top-level ICU argument names used in [message], e.g. `{count, plural, ...}`
/// and `{name}` yield `count` and `name`. Nested plural/select branches are
/// scanned too, so a placeholder used only inside a branch still counts.
Set<String> placeholdersOf(String message) {
  final names = <String>{};
  final pattern = RegExp(r'\{\s*([A-Za-z_][A-Za-z0-9_]*)\s*(?:,|\})');
  for (final m in pattern.allMatches(message)) {
    names.add(m.group(1)!);
  }
  return names;
}
