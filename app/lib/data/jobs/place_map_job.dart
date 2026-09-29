import '../../domain/models/enums.dart';
import '../../domain/services/map_sketch.dart';
import '../db/app_database.dart';
import '../db/tables.dart';
import '../remote/overpass_client.dart';
import '../repositories/place_map_repository.dart';
import '../repositories/trip_repository.dart';
import 'job_runner.dart';

/// Fetches the map around a trip's approximate point, once per area. Does
/// nothing for private trips: their cards never show a map.
class PlaceMapJobHandler implements JobHandler {
  PlaceMapJobHandler({
    required this._trips,
    required this._maps,
    required this._client,
    required this._secret,
  });

  final TripRepository _trips;
  final PlaceMapRepository _maps;
  final OverpassClient _client;
  final Future<List<int>> Function() _secret;

  @override
  JobKind get kind => JobKind.placeMap;

  @override
  Future<JobOutcome> run(JobRow job) async {
    final trip = await _trips.getTrip(job.subjectId);
    final spot = trip?.location;
    if (trip == null || spot == null) return const JobDone();
    if (trip.privacyLevel == PrivacyLevel.private ||
        trip.privacyLevel == PrivacyLevel.friends) {
      return const JobDone();
    }
    final area = mapAreaFor(spot, await _secret());
    if (await _maps.has(area.key)) return const JobDone();
    await _maps.save(area.key, await _client.fetchAround(area.center));
    return const JobDone();
  }

  @override
  Future<void> giveUp(JobRow job) async {}
}
