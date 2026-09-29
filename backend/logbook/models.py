"""The server copy of each person's logbook, mirroring the app's tables.

Rows keep the client's ids (UUID v7) and timestamps: `updated_at` decides
conflicts (last write wins) and `deleted_at` is a tombstone, so deletions
reach every device. `server_seq` orders changes for pulls.
"""

from django.conf import settings
from django.contrib.gis.db import models


class Synced(models.Model):
    id = models.UUIDField(primary_key=True)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="+"
    )
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()
    deleted_at = models.DateTimeField(null=True, blank=True)
    server_seq = models.BigIntegerField(db_index=True)

    class Meta:
        abstract = True


class Trip(Synced):
    started_at = models.DateTimeField()
    ended_at = models.DateTimeField(null=True, blank=True)
    timezone = models.CharField(max_length=64)
    location = models.PointField(geography=True, null=True, blank=True)
    location_accuracy_m = models.FloatField(null=True, blank=True)
    location_name = models.CharField(max_length=200, null=True, blank=True)
    location_region = models.CharField(max_length=200, null=True, blank=True)
    privacy_level = models.CharField(max_length=16)
    moon_phase = models.CharField(max_length=24)
    moon_illumination = models.FloatField()
    notes = models.TextField(null=True, blank=True)
    is_retroactive = models.BooleanField(default=False)


class Bait(Synced):
    name = models.CharField(max_length=120)
    type = models.CharField(max_length=24)
    notes = models.TextField(null=True, blank=True)
    archived = models.BooleanField(default=False)


class Gear(Synced):
    name = models.CharField(max_length=120)
    type = models.CharField(max_length=24)
    notes = models.TextField(null=True, blank=True)
    archived = models.BooleanField(default=False)


class CustomSpecies(Synced):
    """A species the person added (the catalog itself ships with the app)."""

    scientific_name = models.CharField(max_length=200)
    habitats = models.CharField(max_length=200, blank=True)
    region_tags = models.CharField(max_length=200, blank=True)
    names = models.JSONField(default=list)


class Catch(Synced):
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name="catches")
    # A catalog slug or a custom species id.
    species_id = models.CharField(max_length=64, null=True, blank=True)
    caught_at = models.DateTimeField()
    weight_g = models.IntegerField(null=True, blank=True)
    length_mm = models.IntegerField(null=True, blank=True)
    released = models.BooleanField(null=True, blank=True)
    bait = models.ForeignKey(Bait, on_delete=models.SET_NULL, null=True, blank=True)
    gear = models.ForeignKey(Gear, on_delete=models.SET_NULL, null=True, blank=True)
    depth_mm = models.IntegerField(null=True, blank=True)
    location = models.PointField(geography=True, null=True, blank=True)
    notes = models.TextField(null=True, blank=True)


class CatchPhoto(Synced):
    catch = models.ForeignKey(Catch, on_delete=models.CASCADE, related_name="photos")
    width = models.IntegerField()
    height = models.IntegerField()
    taken_at = models.DateTimeField(null=True, blank=True)
    sort_order = models.IntegerField(default=0)
    # Where the image is stored, once uploaded.
    file_name = models.CharField(max_length=200, blank=True)

    @property
    def has_file(self) -> bool:
        return bool(self.file_name)
