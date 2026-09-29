from django.contrib import admin

from .models import User


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ("email", "date_joined", "last_login", "is_staff")
    search_fields = ("email",)
    exclude = ("password", "privacy_secret")
