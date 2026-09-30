import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/background.dart';
import '../../../core/formatting/formatters.dart';
import '../../../data/remote/piscatio_api.dart';
import '../../../domain/models/geo_point.dart';
import '../../../domain/models/venue.dart';
import '../../../domain/services/map_sketch.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Why a venue search returned nothing to show.
enum VenueSearchProblem { signedOut, offline }

class VenueSearchFailure implements Exception {
  const VenueSearchFailure(this.problem);

  final VenueSearchProblem problem;
}

/// Finds listed venues on the server and keeps them for offline display.
/// Searches around a trip use its approximate point, never the spot.
class VenueSearch {
  VenueSearch(this._ref);

  final Ref _ref;

  Future<List<Venue>> search({String query = '', GeoPoint? near}) async {
    final accounts = _ref.read(accountRepositoryProvider);
    final account = await accounts.read();
    final token = await accounts.token();
    if (account == null || token == null) {
      throw const VenueSearchFailure(VenueSearchProblem.signedOut);
    }
    GeoPoint? around;
    if (near != null) {
      final secret = await _ref.read(privacySecretProvider.future);
      around = MapView.coarseOffset(secret).approximate(near);
    }
    try {
      final found = await _ref
          .read(apiFactoryProvider)(account.server, token)
          .searchVenues(
            query: query.trim(),
            lat: around?.latitude,
            lon: around?.longitude,
          );
      await _ref.read(venueRepositoryProvider).remember(found);
      return [for (final v in found) Venue.fromJson(v)];
    } on ApiUnavailable {
      throw const VenueSearchFailure(VenueSearchProblem.offline);
    } on ApiRejected {
      throw const VenueSearchFailure(VenueSearchProblem.offline);
    } on ApiSignedOut {
      throw const VenueSearchFailure(VenueSearchProblem.signedOut);
    }
  }
}

final venueSearchProvider = Provider(VenueSearch.new);

String venueKindName(AppLocalizations l10n, VenueKind kind) => switch (kind) {
  VenueKind.payLake => l10n.venueKindPayLake,
  VenueKind.lodge => l10n.venueKindLodge,
  VenueKind.guide => l10n.venueKindGuide,
  VenueKind.shop => l10n.venueKindShop,
  VenueKind.marina => l10n.venueKindMarina,
  VenueKind.charter => l10n.venueKindCharter,
  VenueKind.other => l10n.venueKindOther,
};

/// "Pesqueiro, Cuiabá, MT, 12 km".
String venueSubtitle(AppLocalizations l10n, Formatters f, Venue v) => [
  venueKindName(l10n, v.kind),
  if (v.place.isNotEmpty) v.place,
  if (v.distanceKm != null) f.distanceKm(v.distanceKm!),
].join(', ');
