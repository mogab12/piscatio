import '../models/trip.dart';

/// When a new catch happened, if the user does not say otherwise:
/// the photo's capture time when it falls within the trip (a photo picked
/// from the gallery minutes later still gets the right time), otherwise now
/// for a running trip, or the trip's end for a past one.
DateTime defaultCatchTime({
  required Trip trip,
  required DateTime now,
  DateTime? photoTakenAt,
}) {
  final windowStart = trip.startedAt.subtract(const Duration(minutes: 30));
  final windowEnd = (trip.endedAt ?? now).add(const Duration(minutes: 5));
  if (photoTakenAt != null &&
      !photoTakenAt.isBefore(windowStart) &&
      !photoTakenAt.isAfter(windowEnd)) {
    return photoTakenAt.toUtc();
  }
  return (trip.endedAt ?? now).toUtc();
}
