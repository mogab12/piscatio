import 'dart:convert';
import 'dart:isolate';

import 'package:http/http.dart' as http;

import '../../domain/models/geo_point.dart';
import '../../domain/models/place_map.dart';
import '../../domain/services/overpass_map.dart';

/// The Overpass server is busy or the answer did not come: try later.
class OverpassUnavailable implements Exception {
  const OverpassUnavailable(this.status);

  final int status;

  @override
  String toString() => 'OverpassUnavailable($status)';
}

/// Fetches OpenStreetMap water and roads around a point (ODbL data; the
/// maps drawn from it carry the attribution). Only approximate points are
/// ever sent.
///
/// Phase 2 moves this behind our backend (own cache, fair use of the
/// public server).
class OverpassClient {
  OverpassClient(this._http, {Uri? endpoint})
    : _endpoint = endpoint ?? defaultEndpoint;

  final http.Client _http;
  final Uri _endpoint;

  static final defaultEndpoint = Uri.parse(
    'https://overpass-api.de/api/interpreter',
  );

  /// Bigger answers are refused: they would be slow to process on a phone.
  static const maxBytes = 24 * 1024 * 1024;

  Future<PlaceMap> fetchAround(GeoPoint center) async {
    final response = await _http
        .post(
          _endpoint,
          headers: {'User-Agent': 'Piscatio/1.0 (fishing logbook app)'},
          body: {'data': OverpassMap.query(center)},
        )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) {
      throw OverpassUnavailable(response.statusCode);
    }
    final bytes = response.bodyBytes;
    if (bytes.length > maxBytes) {
      throw FormatException('map data too large: ${bytes.length} bytes');
    }
    // Parsing and simplifying thousands of points: off the UI thread.
    return Isolate.run(
      () => OverpassMap.parse(
        jsonDecode(utf8.decode(bytes)) as Map<String, Object?>,
        center,
      ),
    );
  }
}
