from django.contrib import admin

from .models import FeatureFlag


@admin.register(FeatureFlag)
class FeatureFlagAdmin(admin.ModelAdmin):
    list_display = ("key", "enabled", "rollout_percent", "staff_only")
    list_editable = ("enabled", "rollout_percent", "staff_only")
    filter_horizontal = ("allowed_users",)
