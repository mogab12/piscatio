import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// The server address baked into builds; the person can change it in the
/// account screen (it is theirs to host).
const defaultApiBase = String.fromEnvironment(
  'PISCATIO_API',
  defaultValue: 'https://piscatio-api.onrender.com',
);

/// The server could not be reached or failed: try again later.
class ApiUnavailable implements Exception {
  const ApiUnavailable([this.detail]);

  final Object? detail;

  @override
  String toString() => 'ApiUnavailable($detail)';
}

/// The token is no longer valid: the person has to sign in again.
class ApiSignedOut implements Exception {
  const ApiSignedOut();
}

/// The server refused the request (bad code, invalid data).
class ApiRejected implements Exception {
  const ApiRejected(this.status, this.code);

  final int status;

  /// Machine-readable reason, e.g. `code_invalid`.
  final String? code;

  @override
  String toString() => 'ApiRejected($status, $code)';
}

class ApiSession {
  const ApiSession({required this.token, required this.email});

  final String token;
  final String email;
}

/// One page of changes from the server.
class PullPage {
  const PullPage({
    required this.changes,
    required this.cursor,
    required this.more,
  });

  final Map<String, List<Map<String, Object?>>> changes;
  final int cursor;
  final bool more;
}

class PushResult {
  const PushResult({
    required this.accepted,
    required this.stale,
    required this.rejected,
    required this.needsFile,
  });

  /// (table, id) pairs.
  final List<(String, String)> accepted;
  final List<(String, String)> stale;
  final List<(String, String)> rejected;

  /// Photo ids the server has no image for.
  final List<String> needsFile;
}

/// Current weather near a point (MET Norway, via our server).
class LiveWeather {
  const LiveWeather({
    this.temperatureC,
    this.pressureHpa,
    this.windSpeedKmh,
    this.windFromDeg,
    this.humidityPct,
    this.precipitationNextHourMm,
    this.symbol,
  });

  factory LiveWeather.fromJson(Map<String, Object?> j) => LiveWeather(
    temperatureC: (j['temperature_c'] as num?)?.toDouble(),
    pressureHpa: (j['pressure_hpa'] as num?)?.toDouble(),
    windSpeedKmh: (j['wind_speed_kmh'] as num?)?.toDouble(),
    windFromDeg: (j['wind_from_deg'] as num?)?.toDouble(),
    humidityPct: (j['humidity_pct'] as num?)?.toDouble(),
    precipitationNextHourMm: (j['precipitation_next_hour_mm'] as num?)
        ?.toDouble(),
    symbol: j['symbol'] as String?,
  );

  final double? temperatureC;
  final double? pressureHpa;
  final double? windSpeedKmh;
  final double? windFromDeg;
  final double? humidityPct;
  final double? precipitationNextHourMm;
  final String? symbol;
}

/// The Piscatio server (see `backend/README.md`).
class PiscatioApi {
  PiscatioApi(this._http, {required this.base, this.token});

  final http.Client _http;
  final String base;
  final String? token;

  static const _timeout = Duration(seconds: 30);

  Uri _uri(String path, [Map<String, String>? query]) {
    final root = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return Uri.parse('$root$path').replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    final http.Response r;
    try {
      r = await call().timeout(_timeout);
    } on TimeoutException catch (e) {
      throw ApiUnavailable(e);
    } on http.ClientException catch (e) {
      throw ApiUnavailable(e);
    } on FormatException catch (e) {
      throw ApiUnavailable(e);
    }
    if (r.statusCode == 401) throw const ApiSignedOut();
    if (r.statusCode >= 500 || r.statusCode == 429) {
      throw ApiUnavailable(r.statusCode);
    }
    if (r.statusCode >= 400) {
      String? code;
      try {
        code = (jsonDecode(r.body) as Map)['detail'] as String?;
      } on Object {
        code = null;
      }
      throw ApiRejected(r.statusCode, code);
    }
    return r;
  }

  Future<Object?> _json(Future<http.Response> Function() call) async {
    final r = await _send(call);
    if (r.body.isEmpty) return null;
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  Future<Object?> _post(String path, Object body) => _json(
    () => _http.post(
      _uri(path),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ),
  );

  Future<void> startEmailSignIn(String email) =>
      _post('/api/auth/email/start', {'email': email});

  Future<ApiSession> verifyEmailCode(
    String email,
    String code, {
    required String device,
  }) async {
    final j = await _post('/api/auth/email/verify', {
      'email': email,
      'code': code,
      'device': device,
    }) as Map<String, Object?>;
    return ApiSession(
      token: j['token']! as String,
      email: (j['user']! as Map)['email'] as String,
    );
  }

  Future<void> signOut() => _post('/api/auth/logout', const {});

  /// The account's privacy secret: [proposed] becomes it if it has none.
  Future<String> privacySecret(String proposed) async {
    final j = await _post('/api/me/privacy-secret', {
      'secret': proposed,
    }) as Map<String, Object?>;
    return j['secret']! as String;
  }

  Future<PushResult> push(
    Map<String, List<Map<String, Object?>>> changes,
  ) async {
    final j = await _post('/api/sync/push', {'changes': changes}) as Map;
    List<(String, String)> pairs(Object? list) => [
      for (final e in (list as List? ?? const []))
        ((e as Map)['table'] as String, '${e['id']}'),
    ];
    return PushResult(
      accepted: pairs(j['accepted']),
      stale: pairs(j['stale']),
      rejected: pairs(j['rejected']),
      needsFile: [
        for (final id in (j['needs_file'] as List? ?? const [])) '$id',
      ],
    );
  }

  Future<PullPage> pull(int since) async {
    final j = await _json(
      () => _http.get(
        _uri('/api/sync/pull', {'since': '$since'}),
        headers: _headers,
      ),
    ) as Map<String, Object?>;
    final raw = (j['changes'] as Map?) ?? const {};
    return PullPage(
      changes: {
        for (final MapEntry(:key, :value) in raw.entries)
          key as String: [
            for (final row in (value as List))
              (row as Map).cast<String, Object?>(),
          ],
      },
      cursor: (j['cursor'] as num?)?.toInt() ?? since,
      more: j['more'] == true,
    );
  }

  Future<void> uploadPhoto(String id, Uint8List jpeg) => _send(
    () => _http.put(
      _uri('/api/photos/$id/file'),
      headers: {..._headers, 'Content-Type': 'image/jpeg'},
      body: jpeg,
    ),
  );

  Future<Uint8List> downloadPhoto(String id) async => (await _send(
    () => _http.get(_uri('/api/photos/$id/file'), headers: _headers),
  )).bodyBytes;

  Future<void> deleteAccount() =>
      _send(() => _http.delete(_uri('/api/account'), headers: _headers));

  Future<LiveWeather> weatherNow(double lat, double lon) async =>
      LiveWeather.fromJson(
        await _json(
          () => _http.get(
            _uri('/api/conditions/weather', {'lat': '$lat', 'lon': '$lon'}),
            headers: _headers,
          ),
        ) as Map<String, Object?>,
      );

  /// Raw Overpass JSON for the area around an approximate point.
  Future<Uint8List> mapArea(double lat, double lon) async => (await _send(
    () => _http.get(
      _uri('/api/conditions/map', {
        'lat': lat.toStringAsFixed(5),
        'lon': lon.toStringAsFixed(5),
      }),
      headers: _headers,
    ),
  )).bodyBytes;
}
