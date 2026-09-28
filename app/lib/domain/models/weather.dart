import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather.freezed.dart';
part 'weather.g.dart';

/// `pending`: waiting for data (NASA POWER publishes with a 2–3 day delay);
/// `ok`: fetched; `unavailable`: gave up (no location, or no data after
/// retrying for days). Names are persisted: renaming needs a migration.
enum WeatherStatus { pending, ok, unavailable }

/// Conditions for one UTC hour. All SI; missing values are null.
@freezed
abstract class HourlyWeather with _$HourlyWeather {
  const factory HourlyWeather({
    /// Start of the hour, UTC.
    required DateTime time,
    double? temperatureC,

    /// Reduced to sea level, which is what anglers compare.
    double? pressureHpa,
    double? windSpeedKmh,

    /// Direction the wind comes from, degrees clockwise from north.
    double? windDirectionDeg,
    double? precipitationMm,
    double? humidityPct,
  }) = _HourlyWeather;

  factory HourlyWeather.fromJson(Map<String, dynamic> json) =>
      _$HourlyWeatherFromJson(json);
}

/// Weather for a whole trip: a summary at the trip's start plus the hourly
/// series covering it, so each catch can get its own conditions.
@freezed
abstract class TripWeather with _$TripWeather {
  const factory TripWeather({
    required String tripId,
    required WeatherStatus status,
    String? source,
    DateTime? fetchedAt,
    double? temperatureC,
    double? pressureHpa,

    /// Pressure change over the 3 hours before the trip started (hPa).
    /// Falling pressure is the classic "fish bite before the front" signal.
    double? pressureTrend3hHpa,
    double? windSpeedKmh,
    double? windDirectionDeg,

    /// Total rain during the trip.
    double? precipitationMm,
    double? humidityPct,
    @Default(<HourlyWeather>[]) List<HourlyWeather> hourly,
  }) = _TripWeather;

  const TripWeather._();

  bool get hasData => status == WeatherStatus.ok && temperatureC != null;

  /// The hourly record closest to [instant], if any within 90 minutes.
  HourlyWeather? at(DateTime instant) {
    HourlyWeather? best;
    var bestGap = const Duration(minutes: 91);
    for (final h in hourly) {
      final gap = h.time
          .add(const Duration(minutes: 30))
          .difference(instant)
          .abs();
      if (gap < bestGap) {
        best = h;
        bestGap = gap;
      }
    }
    return best;
  }
}
