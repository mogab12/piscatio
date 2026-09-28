import '../models/geo_point.dart';

/// Date, time and place for a trip logged afterwards, read from its
/// photos (captured before the metadata was stripped).
class PastTripSuggestion {
  const PastTripSuggestion({
    required this.start,
    required this.end,
    this.location,
  });

  final DateTime start;
  final DateTime end;
  final GeoPoint? location;
}

/// From the photos' capture times (UTC) and places: the trip spans the
/// first to the last photo with a little margin, at least an hour, and
/// never ends after [now]. Null when no photo has a time.
PastTripSuggestion? suggestFromPhotos(
  List<({DateTime? takenAt, GeoPoint? location})> photos, {
  required DateTime now,
}) {
  final times = [for (final p in photos) ?p.takenAt?.toUtc()]..sort();
  if (times.isEmpty) return null;
  const margin = Duration(minutes: 15);
  var start = times.first.subtract(margin);
  var end = times.last.add(margin);
  if (end.difference(start) < const Duration(hours: 1)) {
    end = start.add(const Duration(hours: 1));
  }
  if (end.isAfter(now)) {
    end = now;
    if (end.difference(start) < const Duration(hours: 1)) {
      start = end.subtract(const Duration(hours: 1));
    }
  }
  final located = photos.where((p) => p.location != null);
  return PastTripSuggestion(
    start: start,
    end: end,
    location: located.isEmpty ? null : located.first.location,
  );
}
