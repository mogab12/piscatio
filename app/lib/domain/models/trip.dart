import 'package:freezed_annotation/freezed_annotation.dart';

import '../services/moon.dart';
import 'enums.dart';
import 'geo_point.dart';

part 'trip.freezed.dart';
part 'trip.g.dart';

@freezed
abstract class Trip with _$Trip {
  const factory Trip({
    required String id,

    /// UTC.
    required DateTime startedAt,

    /// UTC. Null while the trip is in progress.
    DateTime? endedAt,

    /// IANA time zone where the trip happened, for display.
    required String timezone,
    GeoPoint? location,
    double? locationAccuracyMeters,
    String? locationName,

    /// City/state level description, the most a card may show for
    /// approximate privacy.
    String? locationRegion,
    required PrivacyLevel privacyLevel,
    required MoonPhase moonPhase,
    required double moonIllumination,
    String? notes,
    @Default(false) bool isRetroactive,

    /// The venue (pay lake, lodge…) where it happened, if picked.
    String? venueId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Trip;

  const Trip._();

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

  bool get isActive => endedAt == null;

  /// Elapsed time; for an active trip, up to [now].
  Duration duration(DateTime now) => (endedAt ?? now).difference(startedAt);
}

/// A trip plus aggregate numbers for lists.
@freezed
abstract class TripOverview with _$TripOverview {
  const factory TripOverview({
    required Trip trip,
    required int catchCount,
    required int speciesCount,
    int? maxWeightGrams,
    int? maxLengthMillimeters,

    /// Relative path of a photo to illustrate the trip, if any.
    String? coverPhotoPath,
  }) = _TripOverview;
}
