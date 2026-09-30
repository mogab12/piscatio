from rest_framework import serializers

from .models import HANDLE_PATTERN, RESERVED_HANDLES, Post, Profile, Report


class ProfileWriteSerializer(serializers.Serializer):
    handle = serializers.RegexField(HANDLE_PATTERN)
    display_name = serializers.CharField(max_length=60, trim_whitespace=True)
    bio = serializers.CharField(
        max_length=160, required=False, allow_blank=True, default=""
    )
    is_private = serializers.BooleanField(required=False, default=True)

    def to_internal_value(self, data):
        if isinstance(data, dict) and isinstance(data.get("handle"), str):
            data = {**data, "handle": data["handle"].strip().lower().lstrip("@")}
        return super().to_internal_value(data)

    def validate_handle(self, value):
        if value in RESERVED_HANDLES:
            raise serializers.ValidationError("handle_reserved")
        taken = Profile.objects.filter(handle=value)
        if self.instance is not None:
            taken = taken.exclude(pk=self.instance.pk)
        if taken.exists():
            raise serializers.ValidationError("handle_taken")
        return value


class PostWriteSerializer(serializers.Serializer):
    kind = serializers.ChoiceField(choices=Post.Kind.choices)
    audience = serializers.ChoiceField(choices=Post.Audience.choices)
    trip_id = serializers.UUIDField(required=False, allow_null=True)
    catch_id = serializers.UUIDField(required=False, allow_null=True)
    species_id = serializers.CharField(
        max_length=64, required=False, allow_null=True, allow_blank=True
    )
    venue_id = serializers.UUIDField(required=False, allow_null=True)
    caption = serializers.CharField(
        max_length=500, required=False, allow_blank=True, allow_null=True
    )
    width = serializers.IntegerField(min_value=1, max_value=4096)
    height = serializers.IntegerField(min_value=1, max_value=4096)
    created_at = serializers.DateTimeField()


class ReportSerializer(serializers.Serializer):
    post_id = serializers.UUIDField(required=False, allow_null=True)
    handle = serializers.CharField(max_length=30, required=False, allow_null=True)
    reason = serializers.ChoiceField(choices=Report.Reason.choices)
    note = serializers.CharField(
        max_length=500, required=False, allow_blank=True, default=""
    )

    def validate(self, attrs):
        if not attrs.get("post_id") and not attrs.get("handle"):
            raise serializers.ValidationError("post_id or handle")
        return attrs
