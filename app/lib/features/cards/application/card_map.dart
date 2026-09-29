import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/background.dart';
import '../../../core/providers.dart';
import '../../../domain/services/map_sketch.dart';

/// Whether a trip's cards can have a map, and why not.
enum CardMapState {
  /// The sketch is ready.
  ready,

  /// No place recorded.
  noPlace,

  /// Private trips never show a map.
  private,

  /// Waiting for the map data (needs a connection once).
  pending,

  /// OpenStreetMap has no water around there.
  empty,
}

/// The map a trip's cards may show (null when they may not, or it is not
/// ready), with the reason.
final tripMapProvider =
    Provider.family<({MapSketch? sketch, CardMapState state}), String>((
      ref,
      tripId,
    ) {
      final trip = ref.watch(tripProvider(tripId)).value;
      final spot = trip?.location;
      if (trip == null || spot == null) {
        return (sketch: null, state: CardMapState.noPlace);
      }
      final secret = ref.watch(privacySecretProvider).value;
      if (secret == null) return (sketch: null, state: CardMapState.pending);
      final view = MapView.forPrivacy(trip.privacyLevel, spot, secret);
      if (view == null) return (sketch: null, state: CardMapState.private);
      final area = mapAreaFor(spot, secret);
      final map = ref.watch(placeMapProvider(area.key)).value;
      if (map == null) return (sketch: null, state: CardMapState.pending);
      final sketch = MapSketch.of(map, view);
      return (
        sketch: sketch,
        state: sketch == null ? CardMapState.empty : CardMapState.ready,
      );
    });
