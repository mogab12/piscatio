from django.contrib import admin
from django.utils import timezone

from .models import Block, Follow, Post, Profile, Report


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ("handle", "display_name", "is_private", "created_at")
    search_fields = ("handle", "display_name", "user__email")
    autocomplete_fields = ("user",)


@admin.action(description="Hide from everyone but the author")
def hide(modeladmin, request, queryset):
    queryset.update(hidden_at=timezone.now())


@admin.action(description="Show again")
def unhide(modeladmin, request, queryset):
    queryset.update(hidden_at=None)


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ("id", "author", "kind", "audience", "created_at", "hidden_at")
    list_filter = ("kind", "audience")
    search_fields = ("author__email", "author__profile__handle", "caption")
    actions = [hide, unhide]
    raw_id_fields = ("author", "venue")


@admin.action(description="Mark resolved")
def resolve(modeladmin, request, queryset):
    queryset.update(resolved=True)


@admin.action(description="Hide the reported posts and resolve")
def hide_reported(modeladmin, request, queryset):
    Post.objects.filter(reports__in=queryset).update(hidden_at=timezone.now())
    queryset.update(resolved=True)


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    list_display = ("reason", "post", "profile", "created_at", "resolved")
    list_filter = ("resolved", "reason")
    actions = [resolve, hide_reported]
    raw_id_fields = ("reporter", "post", "profile")


admin.site.register(Follow)
admin.site.register(Block)
