from django.contrib import admin
from django.http import JsonResponse
from django.urls import path

from accounts import views as accounts
from conditions import views as conditions
from flags import views as flags
from logbook import views as logbook
from venues import views as venues


def health(_request):
    return JsonResponse({"ok": True})


urlpatterns = [
    path("health", health),
    path("admin/", admin.site.urls),
    path("api/auth/email/start", accounts.email_start),
    path("api/auth/email/verify", accounts.email_verify),
    path("api/auth/google", accounts.google_login),
    path("api/auth/logout", accounts.logout),
    path("api/me", accounts.me),
    path("api/me/privacy-secret", accounts.privacy_secret),
    path("api/account", logbook.account),
    path("api/sync/push", logbook.sync_push),
    path("api/sync/pull", logbook.sync_pull),
    path("api/photos/<uuid:photo_id>/file", logbook.photo_file),
    path("api/conditions/weather", conditions.weather_now),
    path("api/conditions/map", conditions.map_area),
    path("api/config", flags.config),
    path("api/venues", venues.venues),
    path("api/venues/<uuid:venue_id>", venues.venue),
    path("api/venues/<uuid:venue_id>/favorite", venues.favorite),
    path("api/venues/<uuid:venue_id>/insights", venues.insights),
    path("api/me/venues", venues.my_venues),
]
