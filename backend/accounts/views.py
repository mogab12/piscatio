import logging
import smtplib
from datetime import timedelta

from django.conf import settings
from django.core.mail import send_mail
from django.db import transaction
from django.utils import timezone
from rest_framework import serializers, status
from rest_framework.decorators import api_view, permission_classes, throttle_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle

from .models import AuthToken, EmailCode, User

log = logging.getLogger(__name__)


class AuthThrottle(ScopedRateThrottle):
    scope = "auth"

    def get_cache_key(self, request, view):
        return self.cache_format % {
            "scope": self.scope,
            "ident": self.get_ident(request),
        }


class EmailSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def validate_email(self, value):
        return value.strip().lower()


class VerifySerializer(EmailSerializer):
    code = serializers.RegexField(r"^\d{6}$")
    device = serializers.CharField(max_length=80, required=False, allow_blank=True)


def _session(user: User, device: str) -> dict:
    return {"token": AuthToken.issue(user, device), "user": _me(user)}


def _me(user: User) -> dict:
    return {"id": user.pk, "email": user.email}


@api_view(["POST"])
@permission_classes([AllowAny])
@throttle_classes([AuthThrottle])
def email_start(request):
    """Sends a 6-digit sign-in code. Always answers the same way, so it does
    not reveal whether an account exists."""
    data = EmailSerializer(data=request.data)
    data.is_valid(raise_exception=True)
    email = data.validated_data["email"]
    recent = EmailCode.objects.filter(
        email=email, created_at__gte=timezone.now() - timedelta(hours=1)
    ).count()
    if recent < 5:
        code = EmailCode.issue(email)
        try:
            send_mail(
                "Seu código do Piscatio / Your Piscatio code",
                f"{code}\n\nVálido por 10 minutos. Valid for 10 minutes.",
                settings.DEFAULT_FROM_EMAIL,
                [email],
            )
        except (smtplib.SMTPException, OSError):
            # Wrong credentials, or a host that blocks SMTP: say so instead
            # of a bare 500 (the app shows "try again").
            log.exception("Could not send the sign-in code")
            return Response({"detail": "email_unavailable"}, status=503)
    else:
        log.warning("Too many sign-in codes requested for an address")
    return Response(status=status.HTTP_202_ACCEPTED)


@api_view(["POST"])
@permission_classes([AllowAny])
@throttle_classes([AuthThrottle])
def email_verify(request):
    data = VerifySerializer(data=request.data)
    data.is_valid(raise_exception=True)
    email = data.validated_data["email"]
    code = data.validated_data["code"]
    with transaction.atomic():
        pending = (
            EmailCode.objects.select_for_update()
            .filter(email=email, used=False)
            .order_by("-created_at")
            .first()
        )
        if (
            pending is None
            or pending.expired
            or pending.attempts >= EmailCode.MAX_ATTEMPTS
        ):
            return Response({"detail": "code_expired"}, status=400)
        if not pending.matches(code):
            pending.attempts += 1
            pending.save(update_fields=["attempts"])
            return Response({"detail": "code_invalid"}, status=400)
        pending.used = True
        pending.save(update_fields=["used"])
        user = User.objects.filter(email=email).first() or User.objects.create_user(
            email
        )
    return Response(_session(user, data.validated_data.get("device", "")))


class GoogleSerializer(serializers.Serializer):
    id_token = serializers.CharField()
    device = serializers.CharField(max_length=80, required=False, allow_blank=True)


def verify_google_token(token: str) -> dict:
    """Checks a Google ID token's signature, expiry and audience."""
    from google.auth.transport import requests as google_requests
    from google.oauth2 import id_token

    info = id_token.verify_oauth2_token(token, google_requests.Request())
    if info.get("aud") not in settings.GOOGLE_CLIENT_IDS:
        raise ValueError("wrong audience")
    if not info.get("email_verified"):
        raise ValueError("email not verified")
    return info


@api_view(["POST"])
@permission_classes([AllowAny])
@throttle_classes([AuthThrottle])
def google_login(request):
    if not settings.GOOGLE_CLIENT_IDS:
        return Response({"detail": "google_not_configured"}, status=501)
    data = GoogleSerializer(data=request.data)
    data.is_valid(raise_exception=True)
    try:
        info = verify_google_token(data.validated_data["id_token"])
    except ValueError:
        return Response({"detail": "google_token_invalid"}, status=400)
    email = info["email"].lower()
    user = User.objects.filter(email=email).first() or User.objects.create_user(email)
    return Response(_session(user, data.validated_data.get("device", "")))


@api_view(["GET"])
def me(request):
    return Response(_me(request.user))


@api_view(["POST"])
def logout(request):
    request.auth.delete()
    return Response(status=204)


class SecretSerializer(serializers.Serializer):
    secret = serializers.RegexField(r"^[A-Za-z0-9+/=]{16,64}$")


@api_view(["POST"])
def privacy_secret(request):
    """The account's approximate-location secret. The first device to ask
    sets it; every later device receives the same one."""
    data = SecretSerializer(data=request.data)
    data.is_valid(raise_exception=True)
    with transaction.atomic():
        user = User.objects.select_for_update().get(pk=request.user.pk)
        if not user.privacy_secret:
            user.privacy_secret = data.validated_data["secret"]
            user.save(update_fields=["privacy_secret"])
    return Response({"secret": user.privacy_secret})
