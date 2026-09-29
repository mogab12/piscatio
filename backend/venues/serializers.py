from django.contrib.gis.geos import Point
from rest_framework import serializers

from .models import Venue

PUBLIC_FIELDS = [
    "id",
    "slug",
    "name",
    "kind",
    "description",
    "address",
    "city",
    "state",
    "country",
    "phone",
    "whatsapp",
    "website",
    "instagram",
    "email",
    "species",
    "amenities",
    "hours",
    "verified",
]


class VenueSerializer(serializers.ModelSerializer):
    """A venue's public profile. Its location is public: it is a business."""

    latitude = serializers.SerializerMethodField()
    longitude = serializers.SerializerMethodField()
    distance_km = serializers.SerializerMethodField()
    is_favorite = serializers.SerializerMethodField()

    class Meta:
        model = Venue
        fields = [
            *PUBLIC_FIELDS,
            "latitude",
            "longitude",
            "distance_km",
            "is_favorite",
        ]

    def get_latitude(self, v):
        return v.location.y if v.location else None

    def get_longitude(self, v):
        return v.location.x if v.location else None

    def get_distance_km(self, v):
        d = getattr(v, "distance", None)
        return round(d.km, 1) if d is not None else None

    def get_is_favorite(self, v):
        favorites = self.context.get("favorites")
        return v.pk in favorites if favorites is not None else False


class VenueWriteSerializer(serializers.ModelSerializer):
    """What the venue's own people may edit."""

    latitude = serializers.FloatField(
        min_value=-90, max_value=90, required=False, allow_null=True
    )
    longitude = serializers.FloatField(
        min_value=-180, max_value=180, required=False, allow_null=True
    )

    class Meta:
        model = Venue
        fields = [f for f in PUBLIC_FIELDS if f not in ("id", "slug", "verified")] + [
            "latitude",
            "longitude",
        ]

    def validate_species(self, value):
        if not isinstance(value, list) or len(value) > 200:
            raise serializers.ValidationError("a list of species ids")
        return [str(s)[:64] for s in value]

    def validate_amenities(self, value):
        if not isinstance(value, list) or len(value) > 50:
            raise serializers.ValidationError("a list of amenity codes")
        return [str(s)[:40] for s in value]

    def validate(self, attrs):
        attrs = super().validate(attrs)
        if "latitude" in attrs or "longitude" in attrs:
            lat, lng = attrs.pop("latitude", None), attrs.pop("longitude", None)
            if (lat is None) != (lng is None):
                raise serializers.ValidationError("latitude and longitude go together")
            attrs["location"] = None if lat is None else Point(lng, lat, srid=4326)
        return attrs
