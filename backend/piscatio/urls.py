from django.contrib import admin
from django.http import JsonResponse
from django.urls import path

from accounts import views as accounts
from conditions import views as conditions
from flags import views as flags
from logbook import views as logbook
from social import views as social
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
    path("api/social/profile", social.profile),
    path("api/social/profile/avatar", social.avatar),
    path("api/social/people", social.people),
    path("api/social/people/<str:handle>", social.person),
    path("api/social/people/<str:handle>/posts", social.person_posts),
    path("api/social/people/<str:handle>/followers", social.followers),
    path("api/social/people/<str:handle>/following", social.following),
    path("api/social/people/<str:handle>/follow", social.follow),
    path("api/social/people/<str:handle>/follower", social.follower),
    path("api/social/people/<str:handle>/block", social.block),
    path("api/social/blocks", social.blocks),
    path("api/social/requests", social.follow_requests),
    path("api/social/requests/<str:handle>", social.request_answer),
    path("api/social/feed", social.feed),
    path("api/social/posts/<uuid:post_id>", social.post),
    path("api/social/posts/<uuid:post_id>/image", social.post_image),
    path("api/social/posts/<uuid:post_id>/like", social.like),
    path("api/social/reports", social.report),
    path("api/social/media/<str:token>", social.media_file),
]
