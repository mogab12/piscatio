// Checks the real Overpass service with the app's own query and parser.
// Run by .github/workflows/map-probe.yml (the dev sandbox cannot reach it):
//   dart run tool/overpass_probe.dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:piscatio/data/remote/overpass_client.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/domain/models/place_map.dart';

const _spots = {
  'Pantanal, Cuiabá river': GeoPoint(-16.52, -56.41),
  'Furnas reservoir': GeoPoint(-20.67, -46.32),
  'São Sebastião channel (coast)': GeoPoint(-23.80, -45.40),
  'Mantiqueira streams': GeoPoint(-22.45, -45.48),
};

Future<void> main() async {
  final client = http.Client();
  final overpass = OverpassClient(client);
  var failures = 0;
  for (final MapEntry(key: name, value: point) in _spots.entries) {
    final watch = Stopwatch()..start();
    try {
      final map = await overpass.fetchAround(point);
      final counts = <MapFeatureKind, int>{};
      var points = 0;
      for (final f in map.features) {
        counts[f.kind] = (counts[f.kind] ?? 0) + 1;
        for (final part in f.parts) {
          points += part.length;
        }
      }
      final stored = jsonEncode(map.toJson()).length;
      stdout.writeln(
        '$name: ${watch.elapsedMilliseconds} ms, '
        '${map.features.length} features $counts, $points points, '
        'stored ${(stored / 1024).toStringAsFixed(0)} KB',
      );
      if (!map.features.any((f) => f.kind != MapFeatureKind.road)) {
        stdout.writeln('  no water found');
        failures++;
      }
    } on Object catch (e) {
      stdout.writeln('$name: FAILED after ${watch.elapsedMilliseconds} ms: $e');
      failures++;
    }
    // Be gentle with the public server.
    await Future<void>.delayed(const Duration(seconds: 5));
  }
  client.close();
  exit(failures == 0 ? 0 : 1);
}
