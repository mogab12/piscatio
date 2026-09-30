import 'enums.dart';

/// Where someone stands with a profile they look at.
enum FollowState { none, pending, accepted }

FollowState followStateOf(Object? v) => switch (v) {
  'pending' => FollowState.pending,
  'accepted' => FollowState.accepted,
  _ => FollowState.none,
};

/// What a card post is about. Names match the server's.
enum PostKind {
  catchCard('catch'),
  tripCard('trip'),
  yearCard('year');

  const PostKind(this.wire);

  final String wire;

  static PostKind of(Object? v) =>
      values.firstWhere((k) => k.wire == v, orElse: () => PostKind.catchCard);
}

/// The server's name for an audience: everyone is "public".
String audienceWire(CardAudience a) => switch (a) {
  CardAudience.everyone => 'public',
  CardAudience.friends => 'friends',
};

CardAudience audienceOf(Object? v) =>
    v == 'friends' ? CardAudience.friends : CardAudience.everyone;

class Relationship {
  const Relationship({
    this.following = FollowState.none,
    this.followsYou = false,
    this.friends = false,
    this.blocked = false,
  });

  factory Relationship.fromJson(Map<String, Object?> j) => Relationship(
    following: followStateOf(j['following']),
    followsYou: j['follows_you'] == true,
    friends: j['friends'] == true,
    blocked: j['blocked'] == true,
  );

  final FollowState following;
  final bool followsYou;

  /// They follow each other: friends-only posts reach both.
  final bool friends;

  /// Blocked by the person looking.
  final bool blocked;

  Relationship copyWith({FollowState? following, bool? blocked}) =>
      Relationship(
        following: following ?? this.following,
        followsYou: followsYou,
        friends:
            (following ?? this.following) == FollowState.accepted && followsYou,
        blocked: blocked ?? this.blocked,
      );
}

/// A public profile in the community.
class SocialProfile {
  const SocialProfile({
    required this.handle,
    required this.displayName,
    this.bio = '',
    this.avatarUrl,
    this.isPrivate = true,
    this.followers = 0,
    this.following = 0,
    this.posts = 0,
    this.requests = 0,
    this.relationship,
    this.canSee = true,
  });

  factory SocialProfile.fromJson(Map<String, Object?> j) => SocialProfile(
    handle: j['handle']! as String,
    displayName: j['display_name'] as String? ?? '',
    bio: j['bio'] as String? ?? '',
    avatarUrl: j['avatar_url'] as String?,
    isPrivate: j['is_private'] != false,
    followers: (j['followers'] as num?)?.toInt() ?? 0,
    following: (j['following'] as num?)?.toInt() ?? 0,
    posts: (j['posts'] as num?)?.toInt() ?? 0,
    requests: (j['requests'] as num?)?.toInt() ?? 0,
    relationship: j['relationship'] is Map
        ? Relationship.fromJson(
            (j['relationship']! as Map).cast<String, Object?>(),
          )
        : null,
    canSee: j['can_see'] != false,
  );

  final String handle;
  final String displayName;
  final String bio;
  final String? avatarUrl;

  /// Follows need approval and only followers see the posts.
  final bool isPrivate;
  final int followers;
  final int following;
  final int posts;

  /// Follow requests waiting (own profile only).
  final int requests;

  /// Null on the person's own profile.
  final Relationship? relationship;

  /// Whether the posts and lists are visible to the person looking.
  final bool canSee;

  bool get isMine => relationship == null;
}

/// Someone behind a post.
class PostAuthor {
  const PostAuthor({
    required this.handle,
    required this.displayName,
    this.avatarUrl,
  });

  factory PostAuthor.fromJson(Map<String, Object?> j) => PostAuthor(
    handle: j['handle']! as String,
    displayName: j['display_name'] as String? ?? '',
    avatarUrl: j['avatar_url'] as String?,
  );

  final String handle;
  final String displayName;
  final String? avatarUrl;
}

/// A published card in the feed.
class FeedPost {
  const FeedPost({
    required this.id,
    required this.author,
    required this.kind,
    required this.audience,
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.createdAt,
    this.speciesId,
    this.venueName,
    this.caption,
    this.likeCount = 0,
    this.liked = false,
    this.mine = false,
  });

  factory FeedPost.fromJson(Map<String, Object?> j) => FeedPost(
    id: j['id']! as String,
    author: PostAuthor.fromJson((j['author']! as Map).cast<String, Object?>()),
    kind: PostKind.of(j['kind']),
    audience: audienceOf(j['audience']),
    imageUrl: j['image_url'] as String? ?? '',
    width: (j['width'] as num?)?.toInt() ?? 1,
    height: (j['height'] as num?)?.toInt() ?? 1,
    createdAt: DateTime.parse(j['created_at']! as String).toUtc(),
    speciesId: j['species_id'] as String?,
    venueName: (j['venue'] as Map?)?['name'] as String?,
    caption: j['caption'] as String?,
    likeCount: (j['like_count'] as num?)?.toInt() ?? 0,
    liked: j['liked'] == true,
    mine: j['mine'] == true,
  );

  final String id;
  final PostAuthor author;
  final PostKind kind;
  final CardAudience audience;
  final String imageUrl;
  final int width;
  final int height;
  final DateTime createdAt;
  final String? speciesId;
  final String? venueName;
  final String? caption;
  final int likeCount;
  final bool liked;
  final bool mine;

  double get aspectRatio => height <= 0 ? 1 : width / height;

  FeedPost withLike({required bool liked, required int count}) => FeedPost(
    id: id,
    author: author,
    kind: kind,
    audience: audience,
    imageUrl: imageUrl,
    width: width,
    height: height,
    createdAt: createdAt,
    speciesId: speciesId,
    venueName: venueName,
    caption: caption,
    likeCount: count,
    liked: liked,
    mine: mine,
  );
}

class FeedPage {
  const FeedPage(this.posts, this.next);

  final List<FeedPost> posts;

  /// Continues the listing; null at the end.
  final String? next;
}

/// Why someone reports a post or a profile. Names match the server's.
enum ReportReason { spam, abuse, location, other }

/// Handles as the server accepts them: 3 to 30 of a–z, 0–9, "_" and ".".
final handlePattern = RegExp(r'^[a-z0-9_.]{3,30}$');

/// Lowercase, without spaces or a leading "@".
String normalizeHandle(String input) =>
    input.trim().toLowerCase().replaceFirst(RegExp('^@'), '');

/// A card waiting to go up to the community.
class OutboxPost {
  const OutboxPost({
    required this.id,
    required this.kind,
    required this.audience,
    required this.imagePath,
    required this.createdAt,
    this.caption,
    this.error,
  });

  final String id;
  final PostKind kind;
  final CardAudience audience;

  /// Relative to the app's documents.
  final String imagePath;
  final DateTime createdAt;
  final String? caption;

  /// The server's reason when it refused the post; null while trying.
  final String? error;
}
