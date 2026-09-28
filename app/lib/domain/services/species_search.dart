import 'dart:math' as math;

import '../models/species.dart';
import 'text_normalizer.dart';

class SpeciesMatch {
  const SpeciesMatch({
    required this.species,
    required this.score,
    required this.matchedName,
  });

  final Species species;
  final double score;

  /// The name or synonym that matched the query (to show "also known as").
  final String matchedName;
}

/// In-memory, accent- and case-insensitive search over every common name,
/// regional synonym and scientific name, in all languages. Names in the
/// user's language and species the user catches often rank first.
class SpeciesSearch {
  SpeciesSearch(Iterable<Species> species)
    : _entries = [
        for (final s in species)
          _Entry(s, [
            _Term(s.scientificName, normalizeForSearch(s.scientificName), null),
            for (final n in s.names)
              _Term(n.name, normalizeForSearch(n.name), n),
          ]),
      ];

  final List<_Entry> _entries;

  /// Returns matches for [query], best first. An empty query lists every
  /// species ordered by [usage] (catch count per species id), then name.
  List<SpeciesMatch> search(
    String query, {
    required String lang,
    Map<String, int> usage = const {},
    int? limit,
  }) {
    final q = normalizeForSearch(query);
    final matches = <SpeciesMatch>[];
    for (final entry in _entries) {
      final uses = usage[entry.species.id] ?? 0;
      final usageBoost = math.min(uses, 50) / 5; // at most +10
      if (q.isEmpty) {
        matches.add(
          SpeciesMatch(
            species: entry.species,
            score: usageBoost,
            matchedName: entry.species.displayName(lang),
          ),
        );
        continue;
      }
      _Term? best;
      var bestScore = 0.0;
      for (final term in entry.terms) {
        var score = _matchScore(q, term.normalized);
        if (score == 0) continue;
        if (term.name?.lang == lang) score += 8;
        if (term.name?.isPrimary ?? false) score += 2;
        if (score > bestScore) {
          bestScore = score;
          best = term;
        }
      }
      if (best != null) {
        matches.add(
          SpeciesMatch(
            species: entry.species,
            score: bestScore + usageBoost,
            matchedName: best.original,
          ),
        );
      }
    }
    matches.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return normalizeForSearch(a.species.displayName(lang))
          .compareTo(normalizeForSearch(b.species.displayName(lang)));
    });
    return limit == null ? matches : matches.take(limit).toList();
  }

  /// 100 exact, 80 prefix of the whole name, 60 every query word prefixes a
  /// word of the name (in order-free fashion), 30 substring, 0 no match.
  static double _matchScore(String query, String name) {
    if (name == query) return 100;
    if (name.startsWith(query)) return 80;
    final nameWords = name.split(' ');
    final queryWords = query.split(' ');
    final allWordsPrefix = queryWords.every(
      (qw) => nameWords.any((nw) => nw.startsWith(qw)),
    );
    if (allWordsPrefix) return 60;
    if (name.contains(query)) return 30;
    return 0;
  }
}

class _Entry {
  _Entry(this.species, this.terms);
  final Species species;
  final List<_Term> terms;
}

class _Term {
  _Term(this.original, this.normalized, this.name);
  final String original;
  final String normalized;
  final SpeciesName? name;
}
