import mimetypes
import uuid
from datetime import UTC, datetime, timedelta

from django.core.files.base import ContentFile
from django.core.files.storage import default_storage
from django.db import IntegrityError, transaction
from django.db.models import F, Q
from django.http import FileResponse, Http404
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import (
    api_view,
    authentication_classes,
    parser_classes,
    permission_classes,
)
from rest_framework.parsers import BaseParser, JSONParser
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from venues.models import Venue

from . import media, rules
from .models import Block, Follow, Like, Post, Profile, Report
from .serializers import PostWriteSerializer, ProfileWriteSerializer, ReportSerializer

PAGE = 20
SEARCH_LIMIT = 30
MAX_POSTS_PER_DAY = 50
MAX_IMAGE_BYTES = 8 * 1024 * 1024
MAX_AVATAR_BYTES = 2 * 1024 * 1024
EPOCH = datetime(1970, 1, 1, tzinfo=UTC)
IMAGE_TYPES = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp"}


class ImageParser(BaseParser):
    media_type = "image/*"

    def parse(self, stream, media_type=None, parser_context=None):
        return stream.read(MAX_IMAGE_BYTES + 1)


# Presenting


def _author(request, profile: Profile) -> dict:
    return {
        "handle": profile.handle,
        "display_name": profile.display_name,
        "avatar_url": media.url(request, profile.avatar_name),
    }


def _profile(request, profile: Profile, with_counts=True) -> dict:
    data = {
        **_author(request, profile),
        "bio": profile.bio,
        "is_private": profile.is_private,
    }
    if with_counts:
        user = profile.user
        accepted = Follow.Status.ACCEPTED
        data |= {
            "followers": Follow.objects.filter(followee=user, status=accepted).count(),
            "following": Follow.objects.filter(follower=user, status=accepted).count(),
            "posts": Post.objects.filter(author=user, deleted_at__isnull=True)
            .exclude(image_name="")
            .count(),
        }
    return data


def _relationship(viewer, profile: Profile) -> dict:
    other = profile.user
    return {
        "following": rules.follow_status(viewer, other),
        "follows_you": rules.follows(other, viewer),
        "friends": rules.are_friends(viewer, other),
        "blocked": Block.objects.filter(blocker=viewer, blocked=other).exists(),
    }


def _posts(request, posts) -> list[dict]:
    posts = list(posts)
    liked = set(
        Like.objects.filter(user=request.user, post__in=posts).values_list(
            "post_id", flat=True
        )
    )
    return [
        {
            "id": str(p.pk),
            "author": _author(request, p.author.profile),
            "kind": p.kind,
            "audience": p.audience,
            "species_id": p.species_id or None,
            "venue": {"id": str(p.venue_id), "name": p.venue.name}
            if p.venue_id
            else None,
            "caption": p.caption or None,
            "image_url": media.url(request, p.image_name),
            "width": p.width,
            "height": p.height,
            "like_count": p.like_count,
            "liked": p.pk in liked,
            "mine": p.author_id == request.user.pk,
            "created_at": p.created_at.isoformat().replace("+00:00", "Z"),
        }
        for p in posts
    ]


def _cursor(post: Post) -> str:
    """URL-safe: microseconds since the epoch and the id."""
    return f"{(post.created_at - EPOCH) // timedelta(microseconds=1)}_{post.pk}"


def _page(request, qs) -> Response:
    """Newest first, [PAGE] at a time; `before` continues a listing."""
    before = request.query_params.get("before")
    if before:
        at, _, pk = before.rpartition("_")
        try:
            t = EPOCH + timedelta(microseconds=int(at))
            pk = uuid.UUID(pk)
            qs = qs.filter(Q(created_at__lt=t) | Q(created_at=t, id__lt=pk))
        except (ValueError, TypeError, OverflowError):
            return Response({"detail": "bad_cursor"}, status=400)
    found = list(
        qs.select_related("author__profile", "venue").order_by("-created_at", "-id")[
            : PAGE + 1
        ]
    )
    more = len(found) > PAGE
    found = found[:PAGE]
    return Response(
        {
            "results": _posts(request, found),
            "next": _cursor(found[-1]) if more else None,
        }
    )


# Finding people


def _own(request) -> Profile | None:
    return Profile.objects.filter(user=request.user).first()


def _person(request, handle: str) -> Profile:
    """Someone by handle; a block either way makes them not exist."""
    profile = (
        Profile.objects.select_related("user")
        .filter(handle=handle.strip().lower().lstrip("@"))
        .first()
    )
    if profile is None or (
        profile.user_id != request.user.pk
        and rules.blocked_between(request.user, profile.user)
    ):
        raise Http404
    return profile


def _needs_profile():
    return Response({"detail": "profile_required"}, status=409)


def _save_image(body, content_type, name_base, max_bytes):
    ext = IMAGE_TYPES.get(content_type.split(";")[0].strip())
    if ext is None:
        return None, Response(status=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE)
    if not body or len(body) > max_bytes:
        return None, Response({"detail": "empty_or_too_large"}, status=413)
    name = f"{name_base}.{ext}"
    if default_storage.exists(name):
        default_storage.delete(name)
    default_storage.save(name, ContentFile(body))
    return name, None


def _drop_file(name: str) -> None:
    if name and default_storage.exists(name):
        default_storage.delete(name)


# Own profile


@api_view(["GET", "PUT", "DELETE"])
def profile(request):
    """The person's own profile. PUT sets it up or changes it; DELETE
    leaves the community (profile, posts and follows go; the logbook
    stays)."""
    own = _own(request)
    if request.method == "GET":
        if own is None:
            raise Http404
        pending = Follow.objects.filter(
            followee=request.user, status=Follow.Status.PENDING
        ).count()
        return Response({**_profile(request, own), "requests": pending})
    if request.method == "DELETE":
        if own is not None:
            leave(request.user)
        return Response(status=204)
    data = ProfileWriteSerializer(own, data=request.data)
    data.is_valid(raise_exception=True)
    values = data.validated_data
    try:
        with transaction.atomic():
            if own is None:
                own = Profile.objects.create(user=request.user, **values)
            else:
                opened = own.is_private and not values["is_private"]
                for field, value in values.items():
                    setattr(own, field, value)
                own.save()
                # Going public lets everyone waiting in.
                if opened:
                    Follow.objects.filter(
                        followee=request.user, status=Follow.Status.PENDING
                    ).update(status=Follow.Status.ACCEPTED)
    except IntegrityError:
        return Response({"handle": ["handle_taken"]}, status=400)
    return Response(_profile(request, own))


@api_view(["PUT", "DELETE"])
@parser_classes([ImageParser])
def avatar(request):
    own = _own(request)
    if own is None:
        return _needs_profile()
    if request.method == "DELETE":
        _drop_file(own.avatar_name)
        own.avatar_name = ""
        own.save(update_fields=["avatar_name", "updated_at"])
        return Response(status=204)
    _drop_file(own.avatar_name)
    name, error = _save_image(
        request.data,
        request.content_type,
        f"avatars/{request.user.pk}-{int(timezone.now().timestamp())}",
        MAX_AVATAR_BYTES,
    )
    if error:
        return error
    own.avatar_name = name
    own.save(update_fields=["avatar_name", "updated_at"])
    return Response({"avatar_url": media.url(request, name)})


def leave(user) -> None:
    """Removes someone from the community, files included."""
    for name in Post.objects.filter(author=user).values_list("image_name", flat=True):
        _drop_file(name)
    Post.objects.filter(author=user).delete()
    Follow.objects.filter(Q(follower=user) | Q(followee=user)).delete()
    own = Profile.objects.filter(user=user).first()
    if own is not None:
        _drop_file(own.avatar_name)
        own.delete()


# People


@api_view(["GET"])
def people(request):
    q = (request.query_params.get("q") or "").strip().lstrip("@")[:60]
    if len(q) < 2:
        return Response({"results": []})
    found = (
        Profile.objects.filter(
            Q(handle__icontains=q.lower()) | Q(display_name__unaccent__icontains=q)
        )
        .exclude(user=request.user)
        .exclude(user_id__in=rules.blocked_ids(request.user))
        .order_by("handle")[:SEARCH_LIMIT]
    )
    return Response(
        {"results": [_profile(request, p, with_counts=False) for p in found]}
    )


@api_view(["GET"])
def person(request, handle):
    p = _person(request, handle)
    data = _profile(request, p)
    if p.user_id != request.user.pk:
        data["relationship"] = _relationship(request.user, p)
    data["can_see"] = rules.can_see_profile_content(request.user, p)
    return Response(data)


@api_view(["GET"])
def person_posts(request, handle):
    p = _person(request, handle)
    if not rules.can_see_profile_content(request.user, p):
        return Response({"results": [], "next": None})
    return _page(request, rules.visible_posts(request.user).filter(author=p.user))


def _people_list(request, profiles):
    return Response(
        {"results": [_profile(request, p, with_counts=False) for p in profiles]}
    )


def _ends(request, rows, side: str) -> Response:
    """The people at one end ([side]) of some follows, newest first."""
    rows = (
        rows.filter(**{f"{side}__profile__isnull": False})
        .exclude(**{f"{side}_id__in": rules.blocked_ids(request.user)})
        .select_related(f"{side}__profile")
        .order_by("-created_at")[:500]
    )
    return _people_list(request, [getattr(r, side).profile for r in rows])


@api_view(["GET"])
def followers(request, handle):
    p = _person(request, handle)
    if not rules.can_see_profile_content(request.user, p):
        return _people_list(request, [])
    rows = Follow.objects.filter(followee=p.user, status=Follow.Status.ACCEPTED)
    return _ends(request, rows, "follower")


@api_view(["GET"])
def following(request, handle):
    p = _person(request, handle)
    if not rules.can_see_profile_content(request.user, p):
        return _people_list(request, [])
    rows = Follow.objects.filter(follower=p.user, status=Follow.Status.ACCEPTED)
    return _ends(request, rows, "followee")


@api_view(["POST", "DELETE"])
def follow(request, handle):
    """POST follows (or asks to, when the profile is private); DELETE
    unfollows or withdraws the request."""
    p = _person(request, handle)
    if p.user_id == request.user.pk:
        return Response({"detail": "self"}, status=400)
    if request.method == "DELETE":
        Follow.objects.filter(follower=request.user, followee=p.user).delete()
        return Response({"status": None})
    if _own(request) is None:
        return _needs_profile()
    row, _ = Follow.objects.get_or_create(
        follower=request.user,
        followee=p.user,
        defaults={
            "status": Follow.Status.PENDING if p.is_private else Follow.Status.ACCEPTED
        },
    )
    return Response({"status": row.status})


@api_view(["DELETE"])
def follower(request, handle):
    """Removes someone from the person's own followers."""
    p = _person(request, handle)
    Follow.objects.filter(follower=p.user, followee=request.user).delete()
    return Response(status=204)


@api_view(["POST", "DELETE"])
def block(request, handle):
    p = _person(request, handle) if request.method == "POST" else None
    if request.method == "DELETE":
        target = Profile.objects.filter(handle=handle.lower()).first()
        if target is not None:
            Block.objects.filter(blocker=request.user, blocked=target.user).delete()
        return Response(status=204)
    if p.user_id == request.user.pk:
        return Response({"detail": "self"}, status=400)
    with transaction.atomic():
        Block.objects.get_or_create(blocker=request.user, blocked=p.user)
        Follow.objects.filter(
            Q(follower=request.user, followee=p.user)
            | Q(follower=p.user, followee=request.user)
        ).delete()
    return Response(status=204)


@api_view(["GET"])
def blocks(request):
    return _people_list(
        request,
        Profile.objects.filter(
            user_id__in=Block.objects.filter(blocker=request.user).values("blocked_id")
        ).order_by("handle"),
    )


@api_view(["GET"])
def follow_requests(request):
    """People waiting for the person to accept them."""
    rows = Follow.objects.filter(followee=request.user, status=Follow.Status.PENDING)
    return _ends(request, rows, "follower")


@api_view(["POST", "DELETE"])
def request_answer(request, handle):
    """POST accepts a follow request; DELETE declines it."""
    p = _person(request, handle)
    pending = Follow.objects.filter(
        follower=p.user, followee=request.user, status=Follow.Status.PENDING
    )
    if request.method == "DELETE":
        pending.delete()
    elif not pending.update(status=Follow.Status.ACCEPTED):
        raise Http404
    return Response(status=204)


# Posts


@api_view(["GET"])
def feed(request):
    """following: the person's own posts and those of people they follow.
    discover: public posts from public profiles."""
    posts = rules.visible_posts(request.user)
    if request.query_params.get("scope") == "discover":
        posts = posts.filter(
            audience=Post.Audience.PUBLIC, author__profile__is_private=False
        ).exclude(author=request.user)
    else:
        posts = posts.filter(Q(author=request.user) | Q(viewer_follows=True))
    return _page(request, posts)


@api_view(["GET", "PUT", "DELETE"])
@parser_classes([JSONParser])
def post(request, post_id):
    """PUT publishes (or edits) the person's post; it asks for the image
    until it has one."""
    existing = Post.objects.filter(pk=post_id).select_related("author").first()
    if existing is not None and existing.author_id != request.user.pk:
        if request.method == "GET" and rules.can_see_post(request.user, existing):
            return Response(_posts(request, [existing])[0])
        raise Http404
    if request.method == "GET":
        if existing is None or existing.deleted_at is not None:
            raise Http404
        return Response(_posts(request, [existing])[0])
    if request.method == "DELETE":
        if existing is not None and existing.deleted_at is None:
            _drop_file(existing.image_name)
            existing.image_name = ""
            existing.deleted_at = timezone.now()
            existing.save(update_fields=["image_name", "deleted_at"])
        return Response(status=204)
    if _own(request) is None:
        return _needs_profile()
    if existing is not None and existing.deleted_at is not None:
        return Response({"detail": "deleted"}, status=410)
    data = PostWriteSerializer(data=request.data)
    data.is_valid(raise_exception=True)
    v = data.validated_data
    if existing is None:
        today = Post.objects.filter(
            author=request.user, updated_at__gte=timezone.now() - timedelta(days=1)
        ).count()
        if today >= MAX_POSTS_PER_DAY:
            return Response({"detail": "too_many_posts"}, status=429)
    venue_id = v.get("venue_id")
    # A venue that is gone (or never was) is dropped, not refused.
    if venue_id and not Venue.objects.filter(pk=venue_id).exists():
        venue_id = None
    values = {
        "kind": v["kind"],
        "audience": v["audience"],
        "trip_id": v.get("trip_id"),
        "catch_id": v.get("catch_id"),
        "species_id": v.get("species_id") or "",
        "venue_id": venue_id,
        "caption": (v.get("caption") or "").strip(),
        "width": v["width"],
        "height": v["height"],
        "updated_at": timezone.now(),
    }
    if existing is None:
        existing = Post.objects.create(
            id=post_id,
            author=request.user,
            created_at=min(v["created_at"], timezone.now()),
            **values,
        )
    else:
        for field, value in values.items():
            setattr(existing, field, value)
        existing.save()
    return Response({"needs_image": not existing.image_name})


@api_view(["PUT"])
@parser_classes([ImageParser])
def post_image(request, post_id):
    p = Post.objects.filter(
        pk=post_id, author=request.user, deleted_at__isnull=True
    ).first()
    if p is None:
        raise Http404
    old = p.image_name
    name, error = _save_image(
        request.data,
        request.content_type,
        f"posts/{request.user.pk}/{p.pk}",
        MAX_IMAGE_BYTES,
    )
    if error:
        return error
    if old and old != name:
        _drop_file(old)
    p.image_name = name
    p.save(update_fields=["image_name"])
    return Response(status=204)


@api_view(["POST", "DELETE"])
def like(request, post_id):
    p = Post.objects.filter(pk=post_id).first()
    if p is None or not rules.can_see_post(request.user, p):
        raise Http404
    with transaction.atomic():
        if request.method == "POST":
            _, made = Like.objects.get_or_create(post=p, user=request.user)
            if made:
                Post.objects.filter(pk=p.pk).update(like_count=F("like_count") + 1)
        elif Like.objects.filter(post=p, user=request.user).delete()[0]:
            Post.objects.filter(pk=p.pk, like_count__gt=0).update(
                like_count=F("like_count") - 1
            )
    p.refresh_from_db(fields=["like_count"])
    return Response(
        {
            "like_count": p.like_count,
            "liked": Like.objects.filter(post=p, user=request.user).exists(),
        }
    )


@api_view(["POST"])
def report(request):
    data = ReportSerializer(data=request.data)
    data.is_valid(raise_exception=True)
    v = data.validated_data
    target_post = target_profile = None
    if v.get("post_id"):
        target_post = Post.objects.filter(pk=v["post_id"]).first()
        if target_post is None or not rules.can_see_post(request.user, target_post):
            raise Http404
    else:
        target_profile = _person(request, v["handle"])
    Report.objects.create(
        reporter=request.user,
        post=target_post,
        profile=target_profile,
        reason=v["reason"],
        note=v.get("note", ""),
    )
    return Response(status=201)


@api_view(["GET"])
@authentication_classes([])
@permission_classes([AllowAny])
def media_file(request, token):
    """An image behind a signed link (see media.py)."""
    name = media.resolve(token)
    if name is None or not default_storage.exists(name):
        raise Http404
    response = FileResponse(
        default_storage.open(name),
        content_type=mimetypes.guess_type(name)[0] or "application/octet-stream",
    )
    response["Cache-Control"] = "private, max-age=86400"
    return response


def export(user, request) -> dict:
    """The person's community data, for the account export."""
    own = Profile.objects.filter(user=user).first()
    accepted = Follow.objects.filter(status=Follow.Status.ACCEPTED)

    def handles(rows, side):
        return sorted(
            rows.filter(**{f"{side}__profile__isnull": False}).values_list(
                f"{side}__profile__handle", flat=True
            )
        )

    posts = Post.objects.filter(author=user, deleted_at__isnull=True)
    return {
        "profile": _profile(request, own, with_counts=False) if own else None,
        "posts": _posts(request, posts.select_related("author__profile", "venue"))
        if own
        else [],
        "following": handles(accepted.filter(follower=user), "followee"),
        "followers": handles(accepted.filter(followee=user), "follower"),
        "blocked": handles(Block.objects.filter(blocker=user), "blocked"),
        "liked": [
            str(i)
            for i in Like.objects.filter(user=user).values_list("post_id", flat=True)
        ],
    }
