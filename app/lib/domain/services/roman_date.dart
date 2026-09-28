const _months = [
  'I',
  'II',
  'III',
  'IV',
  'V',
  'VI',
  'VII',
  'VIII',
  'IX',
  'X',
  'XI',
  'XII',
]; // dart format off

/// Date the way natural-history collection labels write it, the same in
/// every language: `12.IX.2026`.
String romanDate(DateTime local) =>
    '${local.day}.${_months[local.month - 1]}.${local.year}';
