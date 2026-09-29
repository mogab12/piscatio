from django.contrib import admin

from .models import Catch, Trip


@admin.register(Trip)
class TripAdmin(admin.ModelAdmin):
    # Operational view only: no locations or notes on screen.
    list_display = ("id", "user", "started_at", "privacy_level", "deleted_at")
    fields = ("id", "user", "started_at", "ended_at", "privacy_level", "deleted_at")
    readonly_fields = fields


@admin.register(Catch)
class CatchAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "caught_at", "species_id", "deleted_at")
    fields = ("id", "user", "caught_at", "species_id", "deleted_at")
    readonly_fields = fields
