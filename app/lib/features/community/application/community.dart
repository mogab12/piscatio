import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/background.dart';
import '../../../data/remote/piscatio_api.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/social.dart';

/// Why a community request did not work, for the message on screen.
enum CommunityProblem {
  offline,
  signedOut,
  handleTaken,
  handleReserved,
  handleInvalid,
  profileRequired,
  notFound,
  other,
}

class CommunityFailure implements Exception {
  const CommunityFailure(this.problem);

  final CommunityProblem problem;

  @override
  String toString() => 'CommunityFailure($problem)';
}

/// The problem a server error stands for.
CommunityProblem problemOf(Object error) => switch (error) {
  CommunityFailure(:final problem) => problem,
  ApiUnavailable() => CommunityProblem.offline,
  ApiSignedOut() => CommunityProblem.signedOut,
  ApiRejected(code: 'handle_taken') => CommunityProblem.handleTaken,
  ApiRejected(code: 'handle_reserved') => CommunityProblem.handleReserved,
  ApiRejected(code: 'profile_required') => CommunityProblem.profileRequired,
  ApiRejected(status: 404) => CommunityProblem.notFound,
  ApiRejected(status: 400) => CommunityProblem.handleInvalid,
  _ => CommunityProblem.other,
};

Future<T> _guard<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on ApiUnavailable catch (e) {
    throw CommunityFailure(problemOf(e));
  } on ApiSignedOut catch (e) {
    throw CommunityFailure(problemOf(e));
  } on ApiRejected catch (e) {
    throw CommunityFailure(problemOf(e));
  }
}

/// Community screens ask again when the person taps "try again", not on
/// their own.
Duration? _noRetry(int count, Object error) => null;

Future<PiscatioApi> _api(Ref ref) => ref.read(socialRepositoryProvider).api();

/// How a picture from the community (card, avatar) is loaded: from the
/// network in the app, from memory in tests.
final socialImageProvider = Provider<ImageProvider Function(String url)>(
  (ref) => NetworkImage.new,
);

/// Re-encodes a picked photo for the profile: about 512 px, JPEG, without
/// metadata (no EXIF place leaves the phone). Null if it cannot be read.
final avatarEncoderProvider =
    Provider<Future<Uint8List?> Function(String path)>(
      (ref) =>
          (path) => FlutterImageCompress.compressWithFile(
            path,
            minWidth: 512,
            minHeight: 512,
            quality: 85,
          ),
    );

/// The person's own profile: null without an account or before they set
/// one up.
final myProfileProvider =
    AsyncNotifierProvider<MyProfileController, SocialProfile?>(
      MyProfileController.new,
      retry: _noRetry,
    );

class MyProfileController extends AsyncNotifier<SocialProfile?> {
  @override
  Future<SocialProfile?> build() async {
    final account = await ref.watch(
      accountProvider.selectAsync((a) => a?.email),
    );
    if (account == null) return null;
    return _guard(() async => (await _api(ref)).myProfile());
  }

  Future<void> save({
    required String handle,
    required String displayName,
    required String bio,
    required bool isPrivate,
  }) async {
    final saved = await _guard(
      () async => (await _api(ref)).saveProfile(
        handle: normalizeHandle(handle),
        displayName: displayName.trim(),
        bio: bio.trim(),
        isPrivate: isPrivate,
      ),
    );
    state = AsyncData(saved);
    ref.invalidate(feedProvider);
  }

  /// A new profile picture (already re-encoded, without metadata).
  Future<void> setAvatar(Uint8List jpeg) async {
    await _guard(() async => (await _api(ref)).uploadAvatar(jpeg));
    ref.invalidateSelf();
  }

  /// Leaves the community: profile, posts and follows go.
  Future<void> leave() async {
    await _guard(() async => (await _api(ref)).deleteProfile());
    state = const AsyncData(null);
    ref.invalidate(feedProvider);
  }
}

/// What a list of posts shows: the feed, discover, or someone's profile.
abstract final class FeedSource {
  static const following = ':following';
  static const discover = ':discover';

  static String person(String handle) => handle;
}

class FeedState {
  const FeedState(this.posts, {this.next, this.loadingMore = false});

  final List<FeedPost> posts;
  final String? next;
  final bool loadingMore;

  bool get hasMore => next != null;
}

/// Posts of a [FeedSource], a page at a time.
final feedProvider = AsyncNotifierProvider.autoDispose
    .family<FeedController, FeedState, String>(
      FeedController.new,
      retry: _noRetry,
    );

class FeedController extends AsyncNotifier<FeedState> {
  FeedController(this.source);

  final String source;

  Future<FeedPage> _fetch(String? before) => _guard(() async {
    final api = await _api(ref);
    return switch (source) {
      FeedSource.following => api.feed(before: before),
      FeedSource.discover => api.feed(discover: true, before: before),
      final handle => api.personPosts(handle, before: before),
    };
  });

  @override
  Future<FeedState> build() async {
    // Own posts show up once their upload finishes.
    ref.listen(outboxProvider, (previous, next) {
      final before = previous?.value?.length ?? 0;
      if ((next.value?.length ?? 0) < before) ref.invalidateSelf();
    });
    final page = await _fetch(null);
    return FeedState(page.posts, next: page.next);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      FeedState(current.posts, next: current.next, loadingMore: true),
    );
    try {
      final page = await _fetch(current.next);
      state = AsyncData(
        FeedState([...current.posts, ...page.posts], next: page.next),
      );
    } on CommunityFailure {
      state = AsyncData(current);
    }
  }

  void _update(FeedPost Function(FeedPost) change, bool Function(FeedPost) at) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      FeedState([
        for (final p in current.posts) at(p) ? change(p) : p,
      ], next: current.next),
    );
  }

  void _removeWhere(bool Function(FeedPost) test) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      FeedState(
        current.posts.where((p) => !test(p)).toList(),
        next: current.next,
      ),
    );
  }
}

/// Someone's public profile, with where the person stands with them.
final personProvider = FutureProvider.autoDispose.family<SocialProfile, String>(
  (ref, handle) => _guard(() async => (await _api(ref)).person(handle)),
  retry: _noRetry,
);

/// People whose handle or name matches (at least two letters).
final peopleSearchProvider = FutureProvider.autoDispose
    .family<List<SocialProfile>, String>((ref, query) async {
      final q = query.trim();
      if (q.length < 2) return const [];
      return _guard(() async => (await _api(ref)).searchPeople(q));
    }, retry: _noRetry);

/// Someone's followers (true) or the people they follow (false).
final followListProvider = FutureProvider.autoDispose
    .family<List<SocialProfile>, (String, bool)>((ref, arg) async {
      final (handle, followers) = arg;
      return _guard(() async {
        final api = await _api(ref);
        return followers ? api.followers(handle) : api.following(handle);
      });
    }, retry: _noRetry);

final followRequestsProvider = FutureProvider.autoDispose<List<SocialProfile>>(
  (ref) => _guard(() async => (await _api(ref)).followRequests()),
  retry: _noRetry,
);

final blockedPeopleProvider = FutureProvider.autoDispose<List<SocialProfile>>(
  (ref) => _guard(() async => (await _api(ref)).blocked()),
  retry: _noRetry,
);

/// Cards waiting to go up (or that the server refused).
final outboxProvider = StreamProvider<List<OutboxPost>>(
  (ref) => ref.watch(socialRepositoryProvider).watchOutbox(),
);

/// What the person does in the community. Every action talks to the
/// server right away (other people's content is online by nature), except
/// publishing, which goes through the outbox and the job queue.
class CommunityController {
  CommunityController(this._ref);

  final Ref _ref;

  Iterable<FeedController> _feeds() sync* {
    for (final source in [FeedSource.following, FeedSource.discover]) {
      if (_ref.exists(feedProvider(source))) {
        yield _ref.read(feedProvider(source).notifier);
      }
    }
  }

  Future<FollowState> follow(String handle) async {
    final state = await _guard(() async => (await _api(_ref)).follow(handle));
    _ref
      ..invalidate(personProvider(handle))
      ..invalidate(myProfileProvider)
      ..invalidate(feedProvider(FeedSource.following));
    return state;
  }

  Future<void> unfollow(String handle) async {
    await _guard(() async => (await _api(_ref)).unfollow(handle));
    _ref
      ..invalidate(personProvider(handle))
      ..invalidate(myProfileProvider)
      ..invalidate(feedProvider(FeedSource.following));
  }

  Future<void> removeFollower(String handle) async {
    await _guard(() async => (await _api(_ref)).removeFollower(handle));
    _ref
      ..invalidate(personProvider(handle))
      ..invalidate(myProfileProvider)
      ..invalidate(followListProvider);
  }

  Future<void> block(String handle) async {
    await _guard(() async => (await _api(_ref)).block(handle));
    for (final feed in _feeds()) {
      feed._removeWhere((p) => p.author.handle == handle);
    }
    _ref
      ..invalidate(personProvider(handle))
      ..invalidate(myProfileProvider)
      ..invalidate(blockedPeopleProvider);
  }

  Future<void> unblock(String handle) async {
    await _guard(() async => (await _api(_ref)).unblock(handle));
    _ref
      ..invalidate(personProvider(handle))
      ..invalidate(blockedPeopleProvider)
      ..invalidate(feedProvider(FeedSource.discover));
  }

  Future<void> answer(String handle, {required bool accept}) async {
    await _guard(
      () async => (await _api(_ref)).answerRequest(handle, accept: accept),
    );
    _ref
      ..invalidate(followRequestsProvider)
      ..invalidate(myProfileProvider);
  }

  /// Likes or unlikes at once on screen; the server's count follows.
  Future<void> like(FeedPost post, {required String source}) async {
    final liked = !post.liked;
    final feed = _ref.read(feedProvider(source).notifier)
      .._update(
        (p) => p.withLike(
          liked: liked,
          count: (p.likeCount + (liked ? 1 : -1)).clamp(0, 1 << 30),
        ),
        (p) => p.id == post.id,
      );
    try {
      final (serverLiked, count) = await _guard(
        () async => (await _api(_ref)).like(post.id, liked: liked),
      );
      feed._update(
        (p) => p.withLike(liked: serverLiked, count: count),
        (p) => p.id == post.id,
      );
    } on CommunityFailure {
      feed._update(
        (p) => p.withLike(liked: post.liked, count: post.likeCount),
        (p) => p.id == post.id,
      );
      rethrow;
    }
  }

  Future<void> deletePost(FeedPost post) async {
    await _guard(() async => (await _api(_ref)).deletePost(post.id));
    for (final feed in _feeds()) {
      feed._removeWhere((p) => p.id == post.id);
    }
    _ref
      ..invalidate(feedProvider(post.author.handle))
      ..invalidate(myProfileProvider);
  }

  Future<void> report({
    String? postId,
    String? handle,
    required ReportReason reason,
  }) => _guard(
    () async =>
        (await _api(_ref))
            .report(postId: postId, handle: handle, reason: reason),
  );

  /// Queues a card for the community; it goes up as soon as possible.
  Future<void> publish({
    required Uint8List png,
    required int width,
    required int height,
    required PostKind kind,
    required CardAudience audience,
    String? tripId,
    String? catchId,
    String? speciesId,
    String? venueId,
    String? caption,
  }) async {
    final id = await _ref
        .read(socialRepositoryProvider)
        .queue(
          png: png,
          width: width,
          height: height,
          kind: kind,
          audience: audience,
          tripId: tripId,
          catchId: catchId,
          speciesId: speciesId,
          venueId: venueId,
          caption: caption,
        );
    await _ref.read(backgroundWorkProvider).uploadPost(id);
  }

  Future<void> retryPost(String id) async {
    await _ref.read(socialRepositoryProvider).retry(id);
    await _ref.read(backgroundWorkProvider).uploadPost(id);
  }

  Future<void> discardPost(String id) =>
      _ref.read(socialRepositoryProvider).discard(id);
}

final communityControllerProvider = Provider(CommunityController.new);
