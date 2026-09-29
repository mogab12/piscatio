from django.contrib import admin

from .models import Plan, Subscription


@admin.register(Plan)
class PlanAdmin(admin.ModelAdmin):
    list_display = ("code", "name", "price_cents", "currency", "interval", "active")


@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ("venue", "plan", "status", "current_period_end", "provider")
    list_filter = ("status", "provider", "plan")
    autocomplete_fields = ("venue",)
