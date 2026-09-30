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

  /// The switches `/api/config` sends.
  final features = <String, bool>{'venues': false};

  /// Listed venues `/api/venues` searches (by name).
  final venues = <Map<String, Object?>>[];
  final venueSearches = <Map<String, String>>[];
  var shareInsights = false;

  /// The account's community profile (`/api/social/profile`); null until
  /// set up.
  Map<String, Object?>? profile;

  /// Other people, by handle, as `/api/social/people/<handle>` shows them.
  final people = <String, Map<String, Object?>>{};

  /// Follows from the account: handle → "pending" or "accepted".
  final follows = <String, String>{};
  final blocks = <String>{};

  /// Handles waiting for the account to accept them.
  final followRequests = <String>[];

  /// Posts of other people in the feed (following) and in discover.
  final feedPosts = <Map<String, Object?>>[];
  final discoverPosts = <Map<String, Object?>>[];

  /// The account's published posts (id → body) and their images.
  final posts = <String, Map<String, Object?>>{};
  final postImages = <String, Uint8List>{};
  final reports = <Map<String, Object?>>[];
  Uint8List? avatar;

  /// A post by [handle] as the feed lists it.
  static Map<String, Object?> post(
    String id, {
    String handle = 'bia',
    String caption = 'Tucunaré de 3 kg',
    int likes = 0,
    bool liked = false,
    String audience = 'public',
  }) => {
    'id': id,
    'author': {'handle': handle, 'display_name': handle, 'avatar_url': null},
    'kind': 'catch',
    'audience': audience,
    'species_id': 'cichla-ocellaris',
    'venue': null,
    'caption': caption,
    'image_url': 'https://media.test/$id.png',
    'width': 1080,
    'height': 1920,
    'like_count': likes,
    'liked': liked,
    'mine': false,
    'created_at': '2026-09-12T09:00:00Z',
  };

  /// Someone else's profile as the server shows it.
  static Map<String, Object?> person(
    String handle, {
    bool private = false,
    String? name,
  }) => {
    'handle': handle,
    'display_name': name ?? handle,
    'bio': '',
    'avatar_url': null,
    'is_private': private,
    'followers': 0,
    'following': 0,
    'posts': 0,
    'can_see': !private,
  };

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
    if (path == '/api/config') return _json({'features': features});
    if (path == '/api/venues') {
      final q = (r.url.queryParameters['q'] ?? '').toLowerCase();
      venueSearches.add(r.url.queryParameters);
      return _json({
        'results': [
          for (final v in venues)
            if (q.isEmpty || '${v['name']}'.toLowerCase().contains(q)) v,
        ],
      });
    }
    if (path == '/api/me') {
      if (r.method == 'PATCH') {
        shareInsights = (jsonDecode(r.body) as Map)['share_insights'] == true;
      }
      return _json({'id': 1, 'email': email, 'share_insights': shareInsights});
    }
    if (path == '/api/conditions/weather') {
      return weather == null
          ? _json({'detail': 'weather_unavailable'}, 503)
          : _json(weather!);
    }
    if (path.startsWith('/api/social/')) return _social(r);
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

  http.Response _social(http.Request r) {
    final path = r.url.path.substring('/api/social'.length);
    final m = r.method;
    Map<String, Object?> body() => r.body.isEmpty
        ? const {}
        : (jsonDecode(r.body) as Map).cast<String, Object?>();
    final noContent = http.Response('', 204);
    if (path == '/profile') {
      if (m == 'GET') {
        return profile == null
            ? _json({'detail': 'not found'}, 404)
            : _json({...profile!, 'requests': followRequests.length});
      }
      if (m == 'DELETE') {
        profile = null;
        return noContent;
      }
      final b = body();
      final handle = '${b['handle']}'.toLowerCase();
      if (people.containsKey(handle)) {
        return _json({
          'handle': ['handle_taken'],
        }, 400);
      }
      profile = {
        'handle': handle,
        'display_name': b['display_name'],
        'bio': b['bio'] ?? '',
        'avatar_url': avatar == null ? null : 'https://media.test/avatar.jpg',
        'is_private': b['is_private'] ?? true,
        'followers': 0,
        'following': follows.values.where((s) => s == 'accepted').length,
        'posts': posts.length,
      };
      return _json(profile!);
    }
    if (path == '/profile/avatar') {
      if (profile == null) return _json({'detail': 'profile_required'}, 409);
      avatar = r.bodyBytes;
      profile!['avatar_url'] = 'https://media.test/avatar.jpg';
      return _json({'avatar_url': profile!['avatar_url']});
    }
    if (path == '/people') {
      final q = (r.url.queryParameters['q'] ?? '').toLowerCase();
      return _json({
        'results': [
          if (q.length >= 2)
            for (final p in people.values)
              if (!blocks.contains(p['handle']) &&
                  ('${p['handle']}${p['display_name']}'.toLowerCase().contains(
                    q,
                  )))
                p,
        ],
      });
    }
    if (path == '/blocks') {
      return _json({
        'results': [for (final h in blocks) person(h)],
      });
    }
    if (path == '/requests') {
      return _json({
        'results': [for (final h in followRequests) people[h] ?? person(h)],
      });
    }
    final answer = RegExp(r'^/requests/([^/]+)$').firstMatch(path);
    if (answer != null) {
      followRequests.remove(answer.group(1));
      return noContent;
    }
    final who = RegExp(r'^/people/([^/]+)(/[a-z]+)?$').firstMatch(path);
    if (who != null) {
      final handle = Uri.decodeComponent(who.group(1)!);
      final p = people[handle];
      if (p == null) return _json({'detail': 'not found'}, 404);
      final state = follows[handle];
      final canSee = p['is_private'] != true || state == 'accepted';
      switch (who.group(2)) {
        case null:
          return _json({
            ...p,
            'can_see': canSee,
            'relationship': {
              'following': state,
              'follows_you': false,
              'friends': false,
              'blocked': blocks.contains(handle),
            },
          });
        case '/posts':
          return _json({
            'results': canSee
                ? [
                    for (final post in [...feedPosts, ...discoverPosts])
                      if ((post['author']! as Map)['handle'] == handle) post,
                  ]
                : <Object>[],
            'next': null,
          });
        case '/followers' || '/following':
          return _json({'results': <Object>[]});
        case '/follow':
          if (m == 'DELETE') {
            follows.remove(handle);
            return _json({'status': null});
          }
          if (profile == null) {
            return _json({'detail': 'profile_required'}, 409);
          }
          final next = p['is_private'] == true ? 'pending' : 'accepted';
          follows[handle] = next;
          return _json({'status': next});
        case '/follower':
          return noContent;
        case '/block':
          if (m == 'DELETE') {
            blocks.remove(handle);
          } else {
            blocks.add(handle);
            follows.remove(handle);
          }
          return noContent;
      }
    }
    if (path == '/feed') {
      final discover = r.url.queryParameters['scope'] == 'discover';
      final source = discover ? discoverPosts : feedPosts;
      return _json({
        'results': [
          for (final post in source)
            if (!blocks.contains((post['author']! as Map)['handle'])) post,
        ],
        'next': null,
      });
    }
    final postMatch = RegExp(r'^/posts/([^/]+)(/[a-z]+)?$').firstMatch(path);
    if (postMatch != null) {
      final id = postMatch.group(1)!;
      switch ((postMatch.group(2), m)) {
        case (null, 'PUT'):
          if (profile == null) {
            return _json({'detail': 'profile_required'}, 409);
          }
          posts[id] = body();
          return _json({'needs_image': !postImages.containsKey(id)});
        case (null, 'DELETE'):
          posts.remove(id);
          postImages.remove(id);
          feedPosts.removeWhere((p) => p['id'] == id);
          return noContent;
        case ('/image', 'PUT'):
          if (!posts.containsKey(id)) return _json({'detail': 'no'}, 404);
          postImages[id] = r.bodyBytes;
          return noContent;
        case ('/like', _):
          final post = [
            ...feedPosts,
            ...discoverPosts,
          ].firstWhere((p) => p['id'] == id);
          final liked = m == 'POST';
          if (liked != post['liked']) {
            post['liked'] = liked;
            post['like_count'] =
                (post['like_count']! as int) + (liked ? 1 : -1);
          }
          return _json({'liked': liked, 'like_count': post['like_count']});
      }
    }
    if (path == '/reports') {
      reports.add(body());
      return http.Response('', 201);
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
