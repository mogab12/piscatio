// Checks the real Overpass service with the app's own query and parser.
// Run by .github/workflows/map-probe.yml (the dev sandbox cannot reach it):
//   dart run tool/overpass_probe.dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:piscatio/data/remote/overpass_client.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/domain/models/place_map.dart';
import 'package:piscatio/domain/services/map_sketch.dart';

const _spots = {
  'Pantanal, Cuiabá river': GeoPoint(-16.52, -56.41),
  'Furnas reservoir': GeoPoint(-20.67, -46.32),
  'São Sebastião channel (coast)': GeoPoint(-23.80, -45.40),
  'Mantiqueira streams': GeoPoint(-22.45, -45.48),
};

/// Share of the view covered by water areas (lakes and sea), by even-odd
/// sampling on a grid.
double waterShare(MapSketch sketch) {
  const n = 60;
  var wet = 0;
  final areas = [
    for (final s in sketch.shapes)
      if (s.kind.isArea) ...s.parts,
  ];
  for (var i = 0; i < n; i++) {
    for (var j = 0; j < n; j++) {
      final x = -1 + 2 * (i + 0.5) / n;
      final y = -1 + 2 * (j + 0.5) / n;
      var inside = false;
      for (final ring in areas) {
        final k = ring.length ~/ 2;
        for (var a = 0, b = k - 1; a < k; b = a++) {
          final ax = ring[a * 2], ay = ring[a * 2 + 1];
          final bx = ring[b * 2], by = ring[b * 2 + 1];
          if ((ay > y) != (by > y) &&
              x < (bx - ax) * (y - ay) / (by - ay) + ax) {
            inside = !inside;
          }
        }
      }
      if (inside) wet++;
    }
  }
  return wet / (n * n);
}

Future<void> main() async {
  final secret = List<int>.generate(32, (i) => i * 11 % 256);
  final client = http.Client();
  final overpass = OverpassClient(client);
  var failures = 0;
  for (final MapEntry(key: name, value: point) in _spots.entries) {
    final watch = Stopwatch()..start();
    try {
      final area = mapAreaFor(point, secret);
      final map = await overpass.fetchAround(area.center);
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
      for (final level in [PrivacyLevel.approximate, PrivacyLevel.exact]) {
        final view = MapView.forPrivacy(level, point, secret)!;
        final sketch = MapSketch.of(map, view);
        stdout.writeln(
          '  ${level.name}: '
          '${sketch == null ? 'no map' : '${sketch.shapes.length} shapes, '
                    'water ${(waterShare(sketch) * 100).round()}%'}',
        );
      }
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
