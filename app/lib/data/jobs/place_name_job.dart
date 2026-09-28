import '../db/app_database.dart';
import '../db/tables.dart';
import '../remote/place_name_service.dart';
import '../repositories/trip_repository.dart';
import 'job_runner.dart';

/// Fills a trip's region ("Cuiabá, MT") from its coordinates. Never
/// overwrites a region the user typed.
class PlaceNameJobHandler implements JobHandler {
  PlaceNameJobHandler({
    required this._trips,
    required this._service,
    required this._languageCode,
  });

  final TripRepository _trips;
  final PlaceNameService _service;
  final String Function() _languageCode;

  @override
  JobKind get kind => JobKind.placeName;

  @override
  Future<JobOutcome> run(JobRow job) async {
    final trip = await _trips.getTrip(job.subjectId);
    final location = trip?.location;
    if (trip == null || location == null) return const JobDone();
    if ((trip.locationRegion ?? '').trim().isNotEmpty) return const JobDone();
    final region = await _service.regionFor(
      location,
      languageCode: _languageCode(),
    );
    if (region != null) await _trips.fillRegion(trip.id, region);
    return const JobDone();
  }

  @override
  Future<void> giveUp(JobRow job) async {}
}
