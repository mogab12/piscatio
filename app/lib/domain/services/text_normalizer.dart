/// Lowercases, strips diacritics and punctuation, and collapses whitespace so
/// that "Traíra", "TRAIRA" and "traíra-" all compare equal.
String normalizeForSearch(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final folded = _folds[char] ?? char;
    buffer.write(_isWordChar(folded) ? folded : ' ');
  }
  return buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

bool _isWordChar(String c) => RegExp(r'[a-z0-9]').hasMatch(c);

// dart format off
const _folds = <String, String>{
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'ō': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u',
  'ç': 'c', 'ñ': 'n', 'ý': 'y', 'ÿ': 'y', 'ß': 'ss', 'æ': 'ae', 'œ': 'oe',
};
// dart format on
