import re
from datetime import timedelta
from unittest import mock

import pytest
from django.core import mail
from django.utils import timezone

from accounts.models import EmailCode, User

pytestmark = pytest.mark.django_db


def last_code():
    return re.search(r"\b(\d{6})\b", mail.outbox[-1].body).group(1)


def test_sign_in_with_an_emailed_code_creates_the_account(api):
    r = api.post("/api/auth/email/start", {"email": " Ana@Example.com "})
    assert r.status_code == 202
    assert mail.outbox[-1].to == ["ana@example.com"]
    r = api.post(
        "/api/auth/email/verify",
        {"email": "ana@example.com", "code": last_code(), "device": "Pixel"},
    )
    assert r.status_code == 200
    token = r.json()["token"]
    assert User.objects.filter(email="ana@example.com").exists()
    api.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    assert api.get("/api/me").json()["email"] == "ana@example.com"


def test_a_code_works_once(api):
    api.post("/api/auth/email/start", {"email": "ana@example.com"})
    code = last_code()
    body = {"email": "ana@example.com", "code": code}
    assert api.post("/api/auth/email/verify", body).status_code == 200
    r = api.post("/api/auth/email/verify", body)
    assert r.status_code == 400


def test_wrong_codes_lock_the_code(api):
    api.post("/api/auth/email/start", {"email": "ana@example.com"})
    code = last_code()
    wrong = f"{(int(code) + 1) % 1_000_000:06d}"
    for _ in range(EmailCode.MAX_ATTEMPTS):
        r = api.post(
            "/api/auth/email/verify", {"email": "ana@example.com", "code": wrong}
        )
        assert r.json()["detail"] == "code_invalid"
    r = api.post("/api/auth/email/verify", {"email": "ana@example.com", "code": code})
    assert r.json()["detail"] == "code_expired"


def test_expired_codes_fail(api):
    api.post("/api/auth/email/start", {"email": "ana@example.com"})
    EmailCode.objects.update(created_at=timezone.now() - timedelta(minutes=11))
    r = api.post(
        "/api/auth/email/verify", {"email": "ana@example.com", "code": last_code()}
    )
    assert r.json()["detail"] == "code_expired"


def test_codes_are_stored_hashed(api):
    api.post("/api/auth/email/start", {"email": "ana@example.com"})
    assert last_code() not in EmailCode.objects.get().code_hash


def test_at_most_five_codes_an_hour(api, settings):
    settings.REST_FRAMEWORK = {
        **settings.REST_FRAMEWORK,
        "DEFAULT_THROTTLE_RATES": {"auth": "100/min", "user": "600/min"},
    }
    for _ in range(7):
        api.post("/api/auth/email/start", {"email": "ana@example.com"})
    assert len(mail.outbox) == 5


def test_a_mail_server_that_fails_is_reported(api):
    with mock.patch(
        "accounts.views.send_mail", side_effect=ConnectionRefusedError("port 587")
    ):
        r = api.post("/api/auth/email/start", {"email": "ana@example.com"})
    assert r.status_code == 503
    assert r.json()["detail"] == "email_unavailable"


def test_no_token_no_data(api):
    assert api.get("/api/me").status_code == 401
    api.credentials(HTTP_AUTHORIZATION="Bearer nope")
    assert api.get("/api/me").status_code == 401


def test_logout_revokes_only_this_device(user):
    from tests.conftest import client_for

    phone, tablet = client_for(user), client_for(user)
    assert phone.post("/api/auth/logout").status_code == 204
    assert phone.get("/api/me").status_code == 401
    assert tablet.get("/api/me").status_code == 200


def test_google_needs_configuration(api):
    r = api.post("/api/auth/google", {"id_token": "x"})
    assert r.status_code == 501


def test_google_sign_in(api, settings):
    settings.GOOGLE_CLIENT_IDS = ["app-client"]
    info = {"email": "Bia@Example.com", "email_verified": True, "aud": "app-client"}
    with mock.patch("accounts.views.verify_google_token", return_value=info):
        r = api.post("/api/auth/google", {"id_token": "signed"})
    assert r.status_code == 200
    assert r.json()["user"]["email"] == "bia@example.com"
    with mock.patch("accounts.views.verify_google_token", side_effect=ValueError):
        assert api.post("/api/auth/google", {"id_token": "bad"}).status_code == 400


def test_the_first_device_sets_the_privacy_secret(client, user):
    from tests.conftest import client_for

    first = client.post("/api/me/privacy-secret", {"secret": "A" * 44})
    assert first.json()["secret"] == "A" * 44
    other = client_for(user).post("/api/me/privacy-secret", {"secret": "B" * 44})
    assert other.json()["secret"] == "A" * 44
