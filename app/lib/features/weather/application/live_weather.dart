import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/background.dart';
import '../../../core/providers.dart';
import '../../../data/remote/piscatio_api.dart';
import '../../../domain/services/map_sketch.dart';

/// How often the weather "now" is asked again while it is on screen.
const liveWeatherRefresh = Duration(minutes: 15);

/// Weather right now at a trip in progress, from MET Norway through our
/// server. Display only, nothing is stored. The server gets the trip's
/// approximate point (at most ~600 m off), never the spot.
///
/// Null when signed out, without a place, or when the server cannot answer:
/// the screen then shows nothing.
final liveWeatherProvider = FutureProvider.autoDispose
    .family<LiveWeather?, String>((ref, tripId) async {
      final server = ref.watch(accountProvider.select((a) => a.value?.server));
      final spot = ref.watch(
        tripProvider(
          tripId,
        ).select((t) => t.value?.isActive == true ? t.value!.location : null),
      );
      if (server == null || spot == null) return null;
      final secret = await ref.watch(privacySecretProvider.future);
      final token = await ref.read(accountRepositoryProvider).token();
      if (token == null) return null;
      final timer = Timer(liveWeatherRefresh, ref.invalidateSelf);
      ref.onDispose(timer.cancel);
      final point = MapView.fineOffset(secret).approximate(spot);
      try {
        return await ref
            .read(apiFactoryProvider)(server, token)
            .weatherNow(point.latitude, point.longitude);
      } on ApiUnavailable {
        return null;
      } on ApiRejected {
        return null;
      } on ApiSignedOut {
        return null;
      }
    });
