import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../domain/services/logbook_stats.dart';
import '../../../domain/services/records.dart';

/// Numbers for the whole logbook, recomputed whenever a trip or catch
/// changes. Null while the data loads.
final logbookStatsProvider = Provider<LogbookStats?>((ref) {
  final trips = ref.watch(tripHistoryProvider).value;
  final catches = ref.watch(allCatchesProvider).value;
  if (trips == null || catches == null) return null;
  return logbookStats(
    [for (final o in trips) o.trip],
    catches,
    ref.watch(clockProvider).now(),
  );
});

/// Heaviest and longest catch per species, biggest first.
final personalBestsProvider = Provider<List<PersonalBest>>((ref) {
  final catches = ref.watch(allCatchesProvider).value ?? const [];
  final bests = personalBests(catches).values.toList()
    ..sort((a, b) {
      final wa = a.heaviest?.weightGrams ?? 0;
      final wb = b.heaviest?.weightGrams ?? 0;
      if (wa != wb) return wb.compareTo(wa);
      return (b.longest?.lengthMillimeters ?? 0).compareTo(
        a.longest?.lengthMillimeters ?? 0,
      );
    });
  return bests;
});
