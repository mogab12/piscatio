from django.db import models


class MapArea(models.Model):
    """OpenStreetMap water around an approximate point, cached for every
    user of the same area (the data changes slowly)."""

    key = models.CharField(max_length=40, primary_key=True)
    body = models.BinaryField()
    fetched_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:
        return self.key
