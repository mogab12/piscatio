import '../models/catch.dart';

enum RecordKind { weight, length }

/// A new personal best for one measure.
class RecordMark {
  const RecordMark({required this.kind, required this.value, this.previous});

  final RecordKind kind;

  /// Grams or millimeters.
  final int value;

  /// The best before this catch; null when this is the first time the
  /// species was weighed/measured.
  final int? previous;

  /// Gain over the previous best as a fraction (0.12 = +12%).
  double? get improvement => previous == null || previous == 0
      ? null
      : (value - previous!) / previous!;
}

class CatchRecordStatus {
  const CatchRecordStatus({
    this.firstOfSpecies = false,
    this.weight,
    this.length,
  });

  static const none = CatchRecordStatus();

  /// The first catch of this species ever logged.
  final bool firstOfSpecies;
  final RecordMark? weight;
  final RecordMark? length;

  bool get isRecord => weight != null || length != null;

  /// What a card should feature: weight first (what anglers brag about),
  /// then length.
  RecordMark? get headline => weight ?? length;
}

/// Record status of [target], judged against the catches of the same
/// species logged *before* it (by capture time, then id for ties). Records
/// are always computed, never stored: editing or deleting an older catch
/// updates them automatically.
CatchRecordStatus recordStatus(Catch target, Iterable<Catch> all) {
  final species = target.speciesId;
  if (species == null) return CatchRecordStatus.none;
  final earlier = [
    for (final c in all)
      if (c.id != target.id && c.speciesId == species && _isBefore(c, target))
        c,
  ];
  if (earlier.isEmpty) return const CatchRecordStatus(firstOfSpecies: true);

  RecordMark? mark(RecordKind kind, int? Function(Catch) measure) {
    final value = measure(target);
    if (value == null) return null;
    int? best;
    for (final c in earlier) {
      final v = measure(c);
      if (v != null && (best == null || v > best)) best = v;
    }
    if (best != null && value <= best) return null;
    return RecordMark(kind: kind, value: value, previous: best);
  }

  return CatchRecordStatus(
    weight: mark(RecordKind.weight, (c) => c.weightGrams),
    length: mark(RecordKind.length, (c) => c.lengthMillimeters),
  );
}

bool _isBefore(Catch a, Catch b) {
  final byTime = a.caughtAt.compareTo(b.caughtAt);
  return byTime < 0 || (byTime == 0 && a.id.compareTo(b.id) < 0);
}

/// Heaviest and longest catch of a species.
class PersonalBest {
  const PersonalBest({required this.speciesId, this.heaviest, this.longest});

  final String speciesId;
  final Catch? heaviest;
  final Catch? longest;
}

/// Best catch per species (earliest wins ties). Species never measured are
/// left out.
Map<String, PersonalBest> personalBests(Iterable<Catch> catches) {
  final sorted = catches.where((c) => c.speciesId != null).toList()
    ..sort((a, b) => _isBefore(a, b) ? -1 : (_isBefore(b, a) ? 1 : 0));
  final heaviest = <String, Catch>{};
  final longest = <String, Catch>{};
  for (final c in sorted) {
    final s = c.speciesId!;
    if (c.weightGrams != null &&
        (heaviest[s] == null || c.weightGrams! > heaviest[s]!.weightGrams!)) {
      heaviest[s] = c;
    }
    if (c.lengthMillimeters != null &&
        (longest[s] == null ||
            c.lengthMillimeters! > longest[s]!.lengthMillimeters!)) {
      longest[s] = c;
    }
  }
  return {
    for (final s in {...heaviest.keys, ...longest.keys})
      s: PersonalBest(speciesId: s, heaviest: heaviest[s], longest: longest[s]),
  };
}
