import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/geo_point.dart';
import '../../domain/models/weather.dart';
import '../../domain/services/weather_summary.dart';

/// Thrown for failed requests. [retryable] is false only for errors that
/// retrying cannot fix (a malformed request).
class PowerException implements Exception {
  const PowerException(this.message, {required this.retryable});

  final String message;
  final bool retryable;

  @override
  String toString() => 'PowerException($message)';
}

/// NASA POWER hourly point API (CC BY 4.0, commercial use allowed, no key).
///
/// Data comes from reanalysis on a ~0.5° grid and is published with a delay
/// of about 2–3 days. Coordinates are rounded to two decimals before being
/// sent: the grid is far coarser, so nothing is lost, and the exact spot
/// never leaves the phone.
class NasaPowerClient {
  NasaPowerClient(this._http, {this.userAgent = 'Piscatio/1.0'});

  final http.Client _http;
  final String userAgent;

  static const source = 'nasa_power';
  static const host = 'power.larc.nasa.gov';
  static const parameters = [
    'T2M',
    'PS',
    'WS10M',
    'WD10M',
    'PRECTOTCORR',
    'RH2M',
  ];

  static Uri hourlyUri(GeoPoint point, DateTime firstDay, DateTime lastDay) {
    String day(DateTime d) {
      final u = d.toUtc();
      return '${u.year.toString().padLeft(4, '0')}'
          '${u.month.toString().padLeft(2, '0')}'
          '${u.day.toString().padLeft(2, '0')}';
    }

    return Uri.https(host, '/api/temporal/hourly/point', {
      'parameters': parameters.join(','),
      'community': 'RE',
      'latitude': point.latitude.toStringAsFixed(2),
      'longitude': point.longitude.toStringAsFixed(2),
      'start': day(firstDay),
      'end': day(lastDay),
      'format': 'JSON',
      'time-standard': 'UTC',
    });
  }

  /// Hourly records (UTC) between the two days, inclusive. Hours the
  /// service has not published yet come back without values.
  Future<List<HourlyWeather>> fetchHourly(
    GeoPoint point,
    DateTime firstDay,
    DateTime lastDay,
  ) async {
    final http.Response response;
    try {
      response = await _http
          .get(
            hourlyUri(point, firstDay, lastDay),
            headers: {'User-Agent': userAgent, 'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));
    } on Exception catch (e) {
      throw PowerException('network: $e', retryable: true);
    }
    final code = response.statusCode;
    if (code != 200) {
      // 422: dates not published yet or out of range; 429/5xx: try later.
      final retryable = code == 422 || code == 429 || code >= 500;
      throw PowerException('HTTP $code', retryable: retryable);
    }
    try {
      return parseHourly(utf8.decode(response.bodyBytes));
    } on FormatException catch (e) {
      throw PowerException('bad response: ${e.message}', retryable: true);
    }
  }

  /// Parses the GeoJSON-like response:
  /// `properties.parameter.<NAME>.<YYYYMMDDHH> = value`, with
  /// `header.fill_value` (usually -999) for missing data and the grid
  /// elevation in `geometry.coordinates[2]`.
  static List<HourlyWeather> parseHourly(String body) {
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('not an object');
    }
    final properties = json['properties'];
    final params = properties is Map ? properties['parameter'] : null;
    if (params is! Map) throw const FormatException('no parameter block');

    final header = json['header'];
    final fill = header is Map && header['fill_value'] is num
        ? (header['fill_value'] as num).toDouble()
        : -999.0;
    final geometry = json['geometry'];
    final coords = geometry is Map ? geometry['coordinates'] : null;
    final elevation = coords is List && coords.length > 2 && coords[2] is num
        ? (coords[2] as num).toDouble()
        : null;

    Map<String, double?> series(String name) {
      final raw = params[name];
      if (raw is! Map) return const {};
      return {
        for (final e in raw.entries)
          '${e.key}': e.value is num && (e.value as num) > fill + 1e-6
              ? (e.value as num).toDouble()
              : null,
      };
    }

    final t2m = series('T2M');
    final ps = series('PS');
    final ws = series('WS10M');
    final wd = series('WD10M');
    final pr = series('PRECTOTCORR');
    final rh = series('RH2M');
    final keys = {
      ...t2m.keys,
      ...ps.keys,
      ...ws.keys,
      ...pr.keys,
    }.where((k) => RegExp(r'^\d{10}$').hasMatch(k)).toList()..sort();

    return [
      for (final k in keys)
        _hour(
          k,
          temperatureC: t2m[k],
          surfaceKpa: ps[k],
          windMs: ws[k],
          windDeg: wd[k],
          rainMm: pr[k],
          humidity: rh[k],
          elevation: elevation,
        ),
    ];
  }

  static HourlyWeather _hour(
    String key, {
    required double? temperatureC,
    required double? surfaceKpa,
    required double? windMs,
    required double? windDeg,
    required double? rainMm,
    required double? humidity,
    required double? elevation,
  }) {
    final time = DateTime.utc(
      int.parse(key.substring(0, 4)),
      int.parse(key.substring(4, 6)),
      int.parse(key.substring(6, 8)),
      int.parse(key.substring(8, 10)),
    );
    double? pressure;
    if (surfaceKpa != null) {
      final surfaceHpa = surfaceKpa * 10;
      pressure = elevation == null || temperatureC == null
          ? surfaceHpa
          : seaLevelPressureHpa(
              surfaceHpa: surfaceHpa,
              elevationMeters: elevation,
              temperatureC: temperatureC,
            );
    }
    return HourlyWeather(
      time: time,
      temperatureC: temperatureC,
      pressureHpa: pressure,
      windSpeedKmh: windMs == null ? null : windMs * 3.6,
      windDirectionDeg: windDeg,
      precipitationMm: rainMm,
      humidityPct: humidity,
    );
  }
}
