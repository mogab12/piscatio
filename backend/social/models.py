"""The community: public profiles, follows, posts of cards, likes, blocks
and reports.

A post is a card the person chose to publish: the rendered image (which
never has coordinates, see the app's card rules) plus a few facts for
search and for venues. Friends are people who follow each other.
"""

from django.conf import settings
from django.db import models
from django.utils import timezone

HANDLE_PATTERN = r"^[a-z0-9_.]{3,30}$"
RESERVED_HANDLES = {
    "admin",
    "api",
    "help",
    "me",
    "moderation",
    "piscatio",
    "root",
    "staff",
    "support",
    "suporte",
}


class Profile(models.Model):
    """A person's public face. Only people who set one up take part in
    the community; everyone else stays a private logbook."""

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="profile"
    )
    handle = models.CharField(max_length=30, unique=True)
    display_name = models.CharField(max_length=60)
    bio = models.CharField(max_length=160, blank=True)
    avatar_name = models.CharField(max_length=200, blank=True)
    # Private: only accepted followers see the posts; follows need approval.
    is_private = models.BooleanField(default=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:
        return f"@{self.handle}"


class Follow(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending"
        ACCEPTED = "accepted"

    follower = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="following"
    )
    followee = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="followers"
    )
    status = models.CharField(max_length=10, choices=Status.choices)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["follower", "followee"], name="one_follow"),
            models.CheckConstraint(
                condition=~models.Q(follower=models.F("followee")),
                name="no_self_follow",
            ),
        ]

    def __str__(self) -> str:
        return f"{self.follower_id} follows {self.followee_id} ({self.status})"


class Block(models.Model):
    """The blocked person no longer finds, follows or sees the blocker,
    and the other way around."""

    blocker = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="blocks"
    )
    blocked = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="+"
    )
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["blocker", "blocked"], name="one_block")
        ]

    def __str__(self) -> str:
        return f"{self.blocker_id} blocked {self.blocked_id}"


class Post(models.Model):
    class Kind(models.TextChoices):
        CATCH = "catch"
        TRIP = "trip"
        YEAR = "year"

    class Audience(models.TextChoices):
        PUBLIC = "public"
        FRIENDS = "friends"

    # The app's id (UUID v7), so an upload that is retried stays one post.
    id = models.UUIDField(primary_key=True)
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="posts"
    )
    kind = models.CharField(max_length=8, choices=Kind.choices)
    audience = models.CharField(max_length=8, choices=Audience.choices)
    # Logbook rows behind the card (ids only: they may never be synced).
    trip_id = models.UUIDField(null=True, blank=True)
    catch_id = models.UUIDField(null=True, blank=True)
    species_id = models.CharField(max_length=64, blank=True, db_index=True)
    venue = models.ForeignKey(
        "venues.Venue",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="posts",
    )
    caption = models.CharField(max_length=500, blank=True)
    image_name = models.CharField(max_length=200, blank=True)
    width = models.PositiveIntegerField(default=0)
    height = models.PositiveIntegerField(default=0)
    like_count = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField(default=timezone.now)
    deleted_at = models.DateTimeField(null=True, blank=True)
    # Set by moderation: hidden from everyone but its author.
    hidden_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes = [models.Index(fields=["-created_at", "-id"], name="post_order")]

    def __str__(self) -> str:
        return f"{self.kind} by {self.author_id}"

    @property
    def published(self) -> bool:
        return bool(self.image_name) and self.deleted_at is None


class Like(models.Model):
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name="likes")
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="+"
    )
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["post", "user"], name="one_like")
        ]

    def __str__(self) -> str:
        return f"{self.user_id} likes {self.post_id}"


class Report(models.Model):
    """Someone flagged a post or a profile for the moderators."""

    class Reason(models.TextChoices):
        SPAM = "spam"
        ABUSE = "abuse"
        LOCATION = "location"
        OTHER = "other"

    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="+"
    )
    post = models.ForeignKey(
        Post, on_delete=models.CASCADE, null=True, blank=True, related_name="reports"
    )
    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="reports",
    )
    reason = models.CharField(max_length=10, choices=Reason.choices)
    note = models.CharField(max_length=500, blank=True)
    created_at = models.DateTimeField(default=timezone.now)
    resolved = models.BooleanField(default=False)

    def __str__(self) -> str:
        return f"{self.reason} report"
