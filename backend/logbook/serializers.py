from django.contrib.gis.geos import Point
from rest_framework import serializers

from venues.models import Venue

from .models import Bait, Catch, CatchPhoto, CustomSpecies, Gear, Trip

SYNC_FIELDS = ["id", "created_at", "updated_at", "deleted_at"]


class LatLngMixin(serializers.Serializer):
    """Exposes a geography point as latitude/longitude, like the app."""

    latitude = serializers.FloatField(
        min_value=-90, max_value=90, required=False, allow_null=True
    )
    longitude = serializers.FloatField(
        min_value=-180, max_value=180, required=False, allow_null=True
    )

    def to_representation(self, instance):
        data = super().to_representation(instance)
        point = instance.location
        data["latitude"] = point.y if point else None
        data["longitude"] = point.x if point else None
        return data

    def validate(self, attrs):
        attrs = super().validate(attrs)
        lat = attrs.pop("latitude", None)
        lng = attrs.pop("longitude", None)
        if (lat is None) != (lng is None):
            raise serializers.ValidationError("latitude and longitude go together")
        attrs["location"] = None if lat is None else Point(lng, lat, srid=4326)
        return attrs


class OwnedRelatedField(serializers.PrimaryKeyRelatedField):
    """A reference to another row of the same person."""

    def get_queryset(self):
        return self.queryset.filter(user=self.context["user"])


class VenueRefField(serializers.PrimaryKeyRelatedField):
    """A venue by id; one that no longer exists is simply dropped, so the
    trip itself is never refused for it."""

    def to_internal_value(self, data):
        try:
            return super().to_internal_value(data)
        except serializers.ValidationError:
            return None


class TripSerializer(LatLngMixin, serializers.ModelSerializer):
    venue_id = VenueRefField(
        source="venue",
        queryset=Venue.objects.all(),
        allow_null=True,
        required=False,
    )

    class Meta:
        model = Trip
        fields = [
            *SYNC_FIELDS,
            "started_at",
            "ended_at",
            "timezone",
            "latitude",
            "longitude",
            "location_accuracy_m",
            "location_name",
            "location_region",
            "privacy_level",
            "moon_phase",
            "moon_illumination",
            "notes",
            "is_retroactive",
            "venue_id",
        ]
        extra_kwargs = {"id": {"validators": [], "read_only": False}}


class BaitSerializer(serializers.ModelSerializer):
    class Meta:
        model = Bait
        fields = [*SYNC_FIELDS, "name", "type", "notes", "archived"]
        extra_kwargs = {"id": {"validators": [], "read_only": False}}


class GearSerializer(serializers.ModelSerializer):
    class Meta:
        model = Gear
        fields = [*SYNC_FIELDS, "name", "type", "notes", "archived"]
        extra_kwargs = {"id": {"validators": [], "read_only": False}}


class SpeciesNameSerializer(serializers.Serializer):
    lang = serializers.CharField(max_length=8)
    name = serializers.CharField(max_length=120)
    is_primary = serializers.BooleanField(default=False)


class CustomSpeciesSerializer(serializers.ModelSerializer):
    names = SpeciesNameSerializer(many=True)

    class Meta:
        model = CustomSpecies
        fields = [*SYNC_FIELDS, "scientific_name", "habitats", "region_tags", "names"]
        extra_kwargs = {"id": {"validators": [], "read_only": False}}

    def validate_names(self, value):
        if len(value) > 20:
            raise serializers.ValidationError("too many names")
        return value


class CatchSerializer(LatLngMixin, serializers.ModelSerializer):
    trip_id = OwnedRelatedField(source="trip", queryset=Trip.objects.all())
    bait_id = OwnedRelatedField(
        source="bait", queryset=Bait.objects.all(), allow_null=True, required=False
    )
    gear_id = OwnedRelatedField(
        source="gear", queryset=Gear.objects.all(), allow_null=True, required=False
    )

    class Meta:
        model = Catch
        fields = [
            *SYNC_FIELDS,
            "trip_id",
            "species_id",
            "caught_at",
            "weight_g",
            "length_mm",
            "released",
            "bait_id",
            "gear_id",
            "depth_mm",
            "latitude",
            "longitude",
            "notes",
        ]
        extra_kwargs = {
            "id": {"validators": [], "read_only": False},
            "weight_g": {"min_value": 0},
            "length_mm": {"min_value": 0},
            "depth_mm": {"min_value": 0},
        }


class CatchPhotoSerializer(serializers.ModelSerializer):
    catch_id = OwnedRelatedField(source="catch", queryset=Catch.objects.all())
    has_file = serializers.BooleanField(read_only=True)

    class Meta:
        model = CatchPhoto
        fields = [
            *SYNC_FIELDS,
            "catch_id",
            "width",
            "height",
            "taken_at",
            "sort_order",
            "has_file",
        ]
        extra_kwargs = {"id": {"validators": [], "read_only": False}}
