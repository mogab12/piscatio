"""Who sees what. Every social view goes through these, so the rules live
in one place:

- A block, either way, hides everything between the two people.
- Friends are people who follow each other (both follows accepted).
- A post for friends reaches only friends.
- A public post reaches everyone when the profile is public, and only
  accepted followers when it is private.
- Hidden (moderated) and deleted posts reach only their author, and
  deleted ones not even the feed.
"""

from django.db.models import Exists, OuterRef, Q, QuerySet

from .models import Block, Follow, Post, Profile


def blocked_between(a, b) -> bool:
    return Block.objects.filter(
        Q(blocker=a, blocked=b) | Q(blocker=b, blocked=a)
    ).exists()


def blocked_ids(user) -> set[int]:
    """Everyone this person blocked or was blocked by."""
    pairs = Block.objects.filter(Q(blocker=user) | Q(blocked=user)).values_list(
        "blocker_id", "blocked_id"
    )
    return {b if a == user.pk else a for a, b in pairs}


def follow_status(follower, followee) -> str | None:
    return (
        Follow.objects.filter(follower=follower, followee=followee)
        .values_list("status", flat=True)
        .first()
    )


def follows(follower, followee) -> bool:
    return follow_status(follower, followee) == Follow.Status.ACCEPTED


def are_friends(a, b) -> bool:
    return follows(a, b) and follows(b, a)


def can_see_profile_content(viewer, profile: Profile) -> bool:
    """Posts, followers and following of [profile]."""
    owner = profile.user
    if viewer.pk == owner.pk:
        return True
    if blocked_between(viewer, owner):
        return False
    return not profile.is_private or follows(viewer, owner)


def visible_posts(viewer) -> QuerySet[Post]:
    """Every published post [viewer] may see, newest first."""
    accepted = Follow.objects.filter(status=Follow.Status.ACCEPTED)
    qs = (
        Post.objects.filter(deleted_at__isnull=True)
        .exclude(image_name="")
        .annotate(
            viewer_follows=Exists(
                accepted.filter(follower=viewer, followee=OuterRef("author"))
            ),
            follows_back=Exists(
                accepted.filter(follower=OuterRef("author"), followee=viewer)
            ),
        )
    )
    public = Q(audience=Post.Audience.PUBLIC) & (
        Q(author__profile__is_private=False) | Q(viewer_follows=True)
    )
    friends = Q(audience=Post.Audience.FRIENDS, viewer_follows=True, follows_back=True)
    reachable = (
        Q(hidden_at__isnull=True, author__profile__isnull=False)
        & ~Q(author_id__in=blocked_ids(viewer))
        & (public | friends)
    )
    return qs.filter(Q(author=viewer) | reachable).order_by("-created_at", "-id")


def can_see_post(viewer, post: Post) -> bool:
    return visible_posts(viewer).filter(pk=post.pk).exists()
