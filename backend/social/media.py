"""Links to post images and avatars.

With S3-compatible storage the storage signs its own short-lived links.
On the local disk, the link carries a signature valid for one to two days
and stays the same all day, so the app can cache the image by link.
"""

import time

from django.core import signing
from django.core.files.storage import FileSystemStorage, default_storage

SALT = "social.media"
DAY = 24 * 60 * 60


def _today() -> int:
    return int(time.time() // DAY)


def url(request, name: str) -> str | None:
    if not name:
        return None
    if not isinstance(default_storage, FileSystemStorage):
        return default_storage.url(name)
    token = signing.Signer(salt=SALT).sign_object([name, _today()])
    return request.build_absolute_uri(f"/api/social/media/{token}")


def resolve(token: str) -> str | None:
    """The file name behind a link, if the link is genuine and recent."""
    try:
        name, day = signing.Signer(salt=SALT).unsign_object(token)
    except (signing.BadSignature, ValueError, TypeError):
        return None
    if not isinstance(name, str) or not isinstance(day, int):
        return None
    return name if 0 <= _today() - day <= 1 else None
