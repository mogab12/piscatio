import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../domain/models/social.dart';

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
        final j = jsonDecode(r.body) as Map;
        // `{"detail": "code"}`, or a field's first error, e.g.
        // `{"handle": ["handle_taken"]}`.
        code =
            j['detail'] as String? ??
            j.values
                .whereType<List<Object?>>()
                .expand((e) => e)
                .whereType<String>()
                .firstOrNull;
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

  /// The switches and limits this account gets (`/api/config`).
  Future<Map<String, Object?>> config() async =>
      (await _json(() => _http.get(_uri('/api/config'), headers: _headers)))!
          as Map<String, Object?>;

  /// Listed venues matching [query], near [lat]/[lon] when given.
  Future<List<Map<String, Object?>>> searchVenues({
    String query = '',
    double? lat,
    double? lon,
    double radiusKm = 100,
  }) async {
    final j = await _json(
      () => _http.get(
        _uri('/api/venues', {
          if (query.isNotEmpty) 'q': query,
          if (lat != null && lon != null) ...{
            'lat': lat.toStringAsFixed(4),
            'lon': lon.toStringAsFixed(4),
            'radius_km': '$radiusKm',
          },
        }),
        headers: _headers,
      ),
    ) as Map<String, Object?>;
    return [
      for (final v in (j['results'] as List? ?? const []))
        (v as Map).cast<String, Object?>(),
    ];
  }

  Future<Map<String, Object?>> venue(String id) async =>
      (await _json(
            () => _http.get(_uri('/api/venues/$id'), headers: _headers),
          ))!
          as Map<String, Object?>;

  /// Turns the consent to share anonymous totals with venues on or off.
  Future<void> setShareInsights(bool share) => _json(
    () => _http.patch(
      _uri('/api/me'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'share_insights': share}),
    ),
  );

  Future<bool> shareInsights() async {
    final j = await _json(
      () => _http.get(_uri('/api/me'), headers: _headers),
    ) as Map<String, Object?>;
    return j['share_insights'] == true;
  }

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

  // Community (see backend/social). Errors come as [ApiRejected] with the
  // server's code, e.g. `profile_required`, `handle_taken`.

  Future<Map<String, Object?>> _getMap(
    String path, [
    Map<String, String>? query,
  ]) async =>
      (await _json(() => _http.get(_uri(path, query), headers: _headers)))!
          as Map<String, Object?>;

  Future<Object?> _put(String path, Object body) => _json(
    () => _http.put(
      _uri(path),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ),
  );

  Future<Object?> _delete(String path) =>
      _json(() => _http.delete(_uri(path), headers: _headers));

  static String _h(String handle) => Uri.encodeComponent(handle);

  static List<SocialProfile> _people(Map<String, Object?> j) => [
    for (final p in (j['results'] as List? ?? const []))
      SocialProfile.fromJson((p as Map).cast<String, Object?>()),
  ];

  static FeedPage _feed(Map<String, Object?> j) => FeedPage([
    for (final p in (j['results'] as List? ?? const []))
      FeedPost.fromJson((p as Map).cast<String, Object?>()),
  ], j['next'] as String?);

  /// The person's own profile; null when they have not set one up.
  Future<SocialProfile?> myProfile() async {
    try {
      return SocialProfile.fromJson(await _getMap('/api/social/profile'));
    } on ApiRejected catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  Future<SocialProfile> saveProfile({
    required String handle,
    required String displayName,
    required String bio,
    required bool isPrivate,
  }) async => SocialProfile.fromJson(
    (await _put('/api/social/profile', {
          'handle': handle,
          'display_name': displayName,
          'bio': bio,
          'is_private': isPrivate,
        }))!
        as Map<String, Object?>,
  );

  /// Leaves the community: profile, posts and follows go.
  Future<void> deleteProfile() => _delete('/api/social/profile');

  Future<void> uploadAvatar(Uint8List jpeg) => _send(
    () => _http.put(
      _uri('/api/social/profile/avatar'),
      headers: {..._headers, 'Content-Type': 'image/jpeg'},
      body: jpeg,
    ),
  );

  Future<List<SocialProfile>> searchPeople(String query) async =>
      _people(await _getMap('/api/social/people', {'q': query}));

  Future<SocialProfile> person(String handle) async =>
      SocialProfile.fromJson(await _getMap('/api/social/people/${_h(handle)}'));

  Future<FeedPage> personPosts(String handle, {String? before}) async => _feed(
    await _getMap('/api/social/people/${_h(handle)}/posts', {
      'before': ?before,
    }),
  );

  Future<List<SocialProfile>> followers(String handle) async =>
      _people(await _getMap('/api/social/people/${_h(handle)}/followers'));

  Future<List<SocialProfile>> following(String handle) async =>
      _people(await _getMap('/api/social/people/${_h(handle)}/following'));

  Future<FollowState> follow(String handle) async => followStateOf(
    ((await _post('/api/social/people/${_h(handle)}/follow', const {}))!
        as Map)['status'],
  );

  Future<void> unfollow(String handle) =>
      _delete('/api/social/people/${_h(handle)}/follow');

  Future<void> removeFollower(String handle) =>
      _delete('/api/social/people/${_h(handle)}/follower');

  Future<void> block(String handle) =>
      _post('/api/social/people/${_h(handle)}/block', const {});

  Future<void> unblock(String handle) =>
      _delete('/api/social/people/${_h(handle)}/block');

  Future<List<SocialProfile>> blocked() async =>
      _people(await _getMap('/api/social/blocks'));

  Future<List<SocialProfile>> followRequests() async =>
      _people(await _getMap('/api/social/requests'));

  Future<void> answerRequest(String handle, {required bool accept}) => accept
      ? _post('/api/social/requests/${_h(handle)}', const {})
      : _delete('/api/social/requests/${_h(handle)}');

  /// [discover]: public posts from public profiles; otherwise the people
  /// the person follows, and their own.
  Future<FeedPage> feed({bool discover = false, String? before}) async => _feed(
    await _getMap('/api/social/feed', {
      'scope': discover ? 'discover' : 'following',
      'before': ?before,
    }),
  );

  /// Publishes (or updates) a post; true when the server has no image yet.
  Future<bool> putPost(String id, Map<String, Object?> body) async =>
      ((await _put('/api/social/posts/$id', body))! as Map)['needs_image'] ==
      true;

  Future<void> uploadPostImage(String id, Uint8List png) => _send(
    () => _http.put(
      _uri('/api/social/posts/$id/image'),
      headers: {..._headers, 'Content-Type': 'image/png'},
      body: png,
    ),
  );

  Future<void> deletePost(String id) => _delete('/api/social/posts/$id');

  /// Likes or unlikes; the server's count after it.
  Future<(bool, int)> like(String id, {required bool liked}) async {
    final path = '/api/social/posts/$id/like';
    final j =
        (liked ? await _post(path, const {}) : await _delete(path))! as Map;
    return (j['liked'] == true, (j['like_count'] as num?)?.toInt() ?? 0);
  }

  Future<void> report({
    String? postId,
    String? handle,
    required ReportReason reason,
    String note = '',
  }) => _post('/api/social/reports', {
    'post_id': ?postId,
    'handle': ?handle,
    'reason': reason.name,
    'note': note,
  });
}
