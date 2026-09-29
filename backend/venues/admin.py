from django.contrib.gis import admin

from billing.models import Subscription

from .models import Venue, VenueMember


class MemberInline(admin.TabularInline):
    model = VenueMember
    extra = 0
    autocomplete_fields = ("user",)


class SubscriptionInline(admin.TabularInline):
    model = Subscription
    extra = 0


@admin.register(Venue)
class VenueAdmin(admin.GISModelAdmin):
    list_display = ("name", "kind", "city", "state", "status", "verified")
    list_filter = ("status", "kind", "verified", "state")
    search_fields = ("name", "city", "slug")
    prepopulated_fields = {"slug": ("name",)}
    inlines = [MemberInline, SubscriptionInline]
