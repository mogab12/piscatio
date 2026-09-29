"""Businesses anglers can find in the app: pay lakes (pesqueiros), lodges,
guides, tackle shops, marinas. Their profile is public (a business address
is not a secret spot); they pay to be listed and to see what anglers who
fish there like (see insights.py), never who they are."""

import uuid

from django.conf import settings
from django.contrib.gis.db import models
from django.db.models import Exists, OuterRef, Q
from django.utils import timezone


class VenueQuerySet(models.QuerySet):
    def listed(self):
        """Published, with a current subscription that includes a listing."""
        from billing.models import Subscription

        now = timezone.now()
        current = Subscription.objects.filter(
            venue=OuterRef("pk"),
            status__in=[Subscription.Status.TRIALING, Subscription.Status.ACTIVE],
            plan__features__contains=["listing"],
        ).filter(Q(current_period_end__isnull=True) | Q(current_period_end__gt=now))
        return self.filter(status=Venue.Status.PUBLISHED).filter(Exists(current))


class Venue(models.Model):
    class Kind(models.TextChoices):
        PAY_LAKE = "pay_lake"
        LODGE = "lodge"
        GUIDE = "guide"
        SHOP = "shop"
        MARINA = "marina"
        CHARTER = "charter"
        OTHER = "other"

    class Status(models.TextChoices):
        DRAFT = "draft"
        PUBLISHED = "published"
        SUSPENDED = "suspended"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    slug = models.SlugField(max_length=80, unique=True)
    name = models.CharField(max_length=120)
    kind = models.CharField(max_length=16, choices=Kind.choices)
    description = models.TextField(blank=True)
    location = models.PointField(geography=True, null=True, blank=True)
    address = models.CharField(max_length=200, blank=True)
    city = models.CharField(max_length=80, blank=True)
    state = models.CharField(max_length=40, blank=True)
    country = models.CharField(max_length=2, default="BR")
    phone = models.CharField(max_length=40, blank=True)
    whatsapp = models.CharField(max_length=40, blank=True)
    website = models.URLField(blank=True)
    instagram = models.CharField(max_length=60, blank=True)
    email = models.EmailField(blank=True)
    # Catalog slugs of the species found there, amenity codes, opening hours.
    species = models.JSONField(default=list, blank=True)
    amenities = models.JSONField(default=list, blank=True)
    hours = models.JSONField(default=dict, blank=True)
    verified = models.BooleanField(default=False)
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.DRAFT
    )
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    objects = VenueQuerySet.as_manager()

    def __str__(self) -> str:
        return self.name


class VenueMember(models.Model):
    """People who run the venue's account in the app."""

    class Role(models.TextChoices):
        OWNER = "owner"
        MANAGER = "manager"
        STAFF = "staff"

    venue = models.ForeignKey(Venue, on_delete=models.CASCADE, related_name="members")
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="venue_roles"
    )
    role = models.CharField(max_length=10, choices=Role.choices)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["venue", "user"], name="one_role_per_venue")
        ]

    def __str__(self) -> str:
        return f"{self.user} · {self.role} · {self.venue}"

    @property
    def can_edit(self) -> bool:
        return self.role in (self.Role.OWNER, self.Role.MANAGER)


class VenueFavorite(models.Model):
    venue = models.ForeignKey(Venue, on_delete=models.CASCADE, related_name="favorites")
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="+"
    )
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["venue", "user"], name="one_favorite")
        ]


class VenueStat(models.Model):
    """Daily counters for the venue's dashboard (no one's identity)."""

    venue = models.ForeignKey(Venue, on_delete=models.CASCADE, related_name="stats")
    day = models.DateField()
    views = models.PositiveIntegerField(default=0)
    impressions = models.PositiveIntegerField(default=0)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["venue", "day"], name="one_stat_per_day")
        ]


def count(venue_ids, field: str) -> None:
    """Adds one to today's [field] counter of each venue."""
    from django.db.models import F

    today = timezone.localdate()
    for venue_id in venue_ids:
        stat, _ = VenueStat.objects.get_or_create(venue_id=venue_id, day=today)
        VenueStat.objects.filter(pk=stat.pk).update(**{field: F(field) + 1})
