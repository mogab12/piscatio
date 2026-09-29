"""Remote switches for features: they ship turned off and are opened later,
to everyone, to a share of people, to staff or to chosen accounts."""

import hashlib

from django.conf import settings
from django.db import models


class FeatureFlag(models.Model):
    key = models.SlugField(max_length=60, unique=True)
    description = models.CharField(max_length=200, blank=True)
    enabled = models.BooleanField(default=False)
    # Share of accounts (0–100) that see it, stable per account.
    rollout_percent = models.PositiveSmallIntegerField(default=100)
    staff_only = models.BooleanField(default=False)
    allowed_users = models.ManyToManyField(
        settings.AUTH_USER_MODEL, blank=True, related_name="+"
    )

    def __str__(self) -> str:
        return self.key

    def is_on_for(self, user) -> bool:
        if not self.enabled:
            return False
        if self.allowed_users.filter(pk=user.pk).exists():
            return True
        if self.staff_only and not user.is_staff:
            return False
        bucket = int(hashlib.sha256(f"{self.key}:{user.pk}".encode()).hexdigest(), 16)
        return bucket % 100 < self.rollout_percent


def flags_for(user) -> dict[str, bool]:
    return {f.key: f.is_on_for(user) for f in FeatureFlag.objects.all()}
