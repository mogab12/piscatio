import pytest
from django.core.cache import cache
from rest_framework.test import APIClient

from accounts.models import AuthToken, User


@pytest.fixture(autouse=True)
def _isolated(settings, tmp_path):
    cache.clear()
    # Test requests are plain HTTP.
    settings.SECURE_SSL_REDIRECT = False
    settings.STORAGES = {
        **settings.STORAGES,
        "default": {
            "BACKEND": "django.core.files.storage.FileSystemStorage",
            "OPTIONS": {"location": str(tmp_path / "media")},
        },
    }


@pytest.fixture
def api():
    return APIClient()


@pytest.fixture
def user(db):
    return User.objects.create_user("ana@example.com")


def client_for(user):
    c = APIClient()
    c.credentials(HTTP_AUTHORIZATION=f"Bearer {AuthToken.issue(user, 'test')}")
    return c


@pytest.fixture
def client(user):
    return client_for(user)
