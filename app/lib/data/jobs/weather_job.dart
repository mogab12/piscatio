import '../../core/clock.dart';
import '../../domain/models/weather.dart';
import '../../domain/services/weather_summary.dart';
import '../db/app_database.dart';
import '../db/tables.dart';
import '../remote/nasa_power_client.dart';
import '../repositories/trip_repository.dart';
import '../repositories/weather_repository.dart';
import 'job_runner.dart';

/// Fetches a finished trip's weather from NASA POWER once it is published.
class WeatherJobHandler implements JobHandler {
  WeatherJobHandler({
    required this._trips,
    required this._weather,
    required this._client,
    required this._clock,
  });

  final TripRepository _trips;
  final WeatherRepository _weather;
  final NasaPowerClient _client;
  final Clock _clock;

  /// POWER publishes meteorological data about 2–3 days late.
  static const publicationDelay = Duration(hours: 60);

  /// While data is missing, check twice a day.
  static const recheck = Duration(hours: 12);

  /// Past this, missing data will not come: give up.
  static const patience = Duration(days: 10);

  static final firstAvailable = DateTime.utc(2001);

  @override
  JobKind get kind => JobKind.weather;

  @override
  Future<JobOutcome> run(JobRow job) async {
    final trip = await _trips.getTrip(job.subjectId);
    if (trip == null) return const JobDone();
    final now = _clock.now();
    if (trip.isActive) return JobRetryAt(now.add(const Duration(hours: 3)));
    final location = trip.location;
    final end = trip.endedAt!;
    if (location == null || trip.startedAt.isBefore(firstAvailable)) {
      await _weather.markUnavailable(trip.id);
      return const JobDone();
    }
    final publishedAt = end.add(publicationDelay);
    if (now.isBefore(publishedAt)) {
      return JobRetryAt(publishedAt, reason: 'not published yet');
    }

    final List<HourlyWeather> hourly;
    try {
      hourly = await _client.fetchHourly(
        location,
        trip.startedAt.subtract(const Duration(hours: 3)),
        end,
      );
    } on PowerException catch (e) {
      if (e.retryable) rethrow;
      await _weather.markUnavailable(trip.id);
      return const JobDone();
    }

    final summary = summarizeWeather(
      tripId: trip.id,
      start: trip.startedAt,
      end: end,
      hourly: hourly,
      fetchedAt: now,
      source: NasaPowerClient.source,
    );
    if (summary == null) {
      if (now.difference(end) > patience) {
        await _weather.markUnavailable(trip.id);
        return const JobDone();
      }
      return JobRetryAt(now.add(recheck), reason: 'hours not published');
    }
    await _weather.save(summary);
    return const JobDone();
  }

  @override
  Future<void> giveUp(JobRow job) async {
    if (await _trips.getTrip(job.subjectId) != null) {
      await _weather.markUnavailable(job.subjectId);
    }
  }
}
