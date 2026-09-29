import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// An in-memory Piscatio server with the backend's rules (see
/// `backend/logbook/sync.py`): last write wins by `updated_at`, tombstones,
/// an ordered change sequence, photo files. One account.
class FakeServer {
  static const email = 'ana@example.com';
  static const token = 'token-ana';
  static const code = '123456';

  final tables = <String, Map<String, Map<String, Object?>>>{};
  final seqOf = <String, int>{};
  final files = <String, Uint8List>{};
  var _seq = 0;
  String? secret;

  /// When true every request fails like a server that is down.
  var down = false;

  /// Rows the server refuses (by id), like invalid data.
  final refuse = <String>{};
  final requests = <http.Request>[];

  /// What `/api/conditions/weather` answers (null: MET is down).
  Map<String, Object?>? weather = {
    'time': '2026-09-12T09:00:00Z',
    'temperature_c': 27.4,
    'pressure_hpa': 1011.8,
    'humidity_pct': 62.0,
    'wind_speed_kmh': 11.2,
    'wind_from_deg': 45.0,
    'precipitation_next_hour_mm': 0.4,
    'symbol': 'partlycloudy_day',
  };

  static const order = [
    'trips',
    'baits',
    'gear',
    'species',
    'catches',
    'photos',
  ];

  http.Client client() => MockClient(_handle);

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  Future<http.Response> _handle(http.Request r) async {
    requests.add(r);
    if (down) return http.Response('down', 503);
    final path = r.url.path;
    if (path == '/api/auth/email/start') return http.Response('', 202);
    if (path == '/api/auth/email/verify') {
      final body = jsonDecode(r.body) as Map;
      if (body['code'] != code) return _json({'detail': 'code_invalid'}, 400);
      return _json({
        'token': token,
        'user': {'id': 1, 'email': body['email']},
      });
    }
    if (r.headers['Authorization'] != 'Bearer $token') {
      return _json({'detail': 'signed out'}, 401);
    }
    if (path == '/api/auth/logout') return http.Response('', 204);
    if (path == '/api/me/privacy-secret') {
      secret ??= (jsonDecode(r.body) as Map)['secret'] as String;
      return _json({'secret': secret});
    }
    if (path == '/api/conditions/weather') {
      return weather == null
          ? _json({'detail': 'weather_unavailable'}, 503)
          : _json(weather!);
    }
    if (path == '/api/sync/push') return _push(r);
    if (path == '/api/sync/pull') return _pull(r);
    if (path == '/api/account' && r.method == 'DELETE') {
      tables.clear();
      files.clear();
      return http.Response('', 204);
    }
    final photo = RegExp(r'^/api/photos/([^/]+)/file$').firstMatch(path);
    if (photo != null) {
      final id = photo.group(1)!;
      final row = tables['photos']?[id];
      if (row == null) return _json({'detail': 'not found'}, 404);
      if (r.method == 'PUT') {
        files[id] = r.bodyBytes;
        seqOf['photos/$id'] = ++_seq;
        return http.Response('', 204);
      }
      final file = files[id];
      return file == null
          ? _json({'detail': 'not found'}, 404)
          : http.Response.bytes(file, 200);
    }
    return http.Response('no route $path', 404);
  }

  http.Response _push(http.Request r) {
    final changes = (jsonDecode(r.body) as Map)['changes'] as Map;
    final accepted = <Map<String, String>>[];
    final stale = <Map<String, String>>[];
    final rejected = <Map<String, String>>[];
    for (final table in order) {
      for (final raw in (changes[table] as List? ?? const [])) {
        final row = (raw as Map).cast<String, Object?>();
        final id = row['id']! as String;
        if (refuse.contains(id)) {
          rejected.add({'table': table, 'id': id});
          continue;
        }
        final existing = tables[table]?[id];
        if (existing != null &&
            (existing['updated_at']! as String).compareTo(
                  row['updated_at']! as String,
                ) >=
                0) {
          stale.add({'table': table, 'id': id});
          continue;
        }
        (tables[table] ??= {})[id] = {...row}..remove('has_file');
        seqOf['$table/$id'] = ++_seq;
        accepted.add({'table': table, 'id': id});
      }
    }
    return _json({
      'accepted': accepted,
      'stale': stale,
      'rejected': rejected,
      'needs_file': [
        for (final e in [...accepted, ...stale])
          if (e['table'] == 'photos' && !files.containsKey(e['id'])) e['id'],
      ],
    });
  }

  http.Response _pull(http.Request r) {
    final since = int.parse(r.url.queryParameters['since'] ?? '0');
    final rows = <(int, String, Map<String, Object?>)>[];
    for (final MapEntry(key: table, value: byId) in tables.entries) {
      for (final MapEntry(key: id, value: row) in byId.entries) {
        final seq = seqOf['$table/$id']!;
        if (seq > since) {
          rows.add((
            seq,
            table,
            {...row, if (table == 'photos') 'has_file': files.containsKey(id)},
          ));
        }
      }
    }
    rows.sort((a, b) => a.$1.compareTo(b.$1));
    return _json({
      'changes': {
        for (final t in order)
          t: [
            for (final r in rows)
              if (r.$2 == t) r.$3,
          ],
      },
      'cursor': rows.isEmpty ? since : rows.last.$1,
      'more': false,
    });
  }
}
