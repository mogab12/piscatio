"""What businesses pay for. A plan lists features (a public listing, the
insights, promotions later); a subscription gives them to one venue while it
is active. Who charges is a provider (see providers.py): manual for now,
Stripe or Mercado Pago later, without touching the rest of the app."""

from django.db import models
from django.utils import timezone


class Plan(models.Model):
    code = models.SlugField(max_length=40, unique=True)
    name = models.CharField(max_length=80)
    price_cents = models.PositiveIntegerField(default=0)
    currency = models.CharField(max_length=3, default="BRL")
    interval = models.CharField(
        max_length=8, choices=[("month", "month"), ("year", "year")], default="month"
    )
    # Feature codes, e.g. ["listing", "insights"].
    features = models.JSONField(default=list, blank=True)
    active = models.BooleanField(default=True)

    def __str__(self) -> str:
        return self.name


class Subscription(models.Model):
    class Status(models.TextChoices):
        TRIALING = "trialing"
        ACTIVE = "active"
        PAST_DUE = "past_due"
        CANCELED = "canceled"

    venue = models.ForeignKey(
        "venues.Venue", on_delete=models.CASCADE, related_name="subscriptions"
    )
    plan = models.ForeignKey(Plan, on_delete=models.PROTECT, related_name="+")
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.TRIALING
    )
    # Null: no end (e.g. granted by hand).
    current_period_end = models.DateTimeField(null=True, blank=True)
    provider = models.CharField(max_length=20, default="manual")
    provider_ref = models.CharField(max_length=120, blank=True)
    created_at = models.DateTimeField(default=timezone.now)

    def __str__(self) -> str:
        return f"{self.venue} · {self.plan}"

    @property
    def is_current(self) -> bool:
        if self.status not in (self.Status.TRIALING, self.Status.ACTIVE):
            return False
        end = self.current_period_end
        return end is None or end > timezone.now()


def entitlements(venue) -> set[str]:
    """Features the venue has right now, from its current subscriptions."""
    features: set[str] = set()
    for sub in venue.subscriptions.select_related("plan"):
        if sub.is_current:
            features.update(sub.plan.features)
    return features
