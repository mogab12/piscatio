from django.utils import timezone
from rest_framework import authentication, exceptions

from .models import AuthToken, sha256


class BearerTokenAuthentication(authentication.BaseAuthentication):
    """`Authorization: Bearer <token>` with a token from sign-in."""

    keyword = "Bearer"

    def authenticate(self, request):
        header = authentication.get_authorization_header(request).split()
        if not header or header[0].lower() != self.keyword.lower().encode():
            return None
        if len(header) != 2:
            raise exceptions.AuthenticationFailed("Invalid token header.")
        raw = header[1].decode(errors="ignore")
        try:
            token = AuthToken.objects.select_related("user").get(key_hash=sha256(raw))
        except AuthToken.DoesNotExist as e:
            raise exceptions.AuthenticationFailed("Invalid token.") from e
        if not token.user.is_active:
            raise exceptions.AuthenticationFailed("Inactive account.")
        now = timezone.now()
        if not token.last_used_at or (now - token.last_used_at).total_seconds() > 3600:
            AuthToken.objects.filter(pk=token.pk).update(last_used_at=now)
        request.auth_token = token
        return token.user, token

    def authenticate_header(self, request):
        return self.keyword
