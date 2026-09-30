from django.core.files.base import ContentFile
from django.core.files.storage import default_storage
from django.db import transaction
from django.http import FileResponse, Http404
from rest_framework import status
from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import BaseParser
from rest_framework.response import Response

from social import views as social

from . import sync
from .models import CatchPhoto

MAX_PHOTO_BYTES = 12 * 1024 * 1024
PHOTO_TYPES = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp"}


@api_view(["POST"])
def sync_push(request):
    changes = request.data.get("changes")
    if not isinstance(changes, dict):
        return Response({"detail": "changes must be an object"}, status=400)
    if sync.count_rows(changes) > sync.MAX_PUSH_ROWS:
        return Response({"detail": "too_many_rows"}, status=413)
    return Response(sync.push(request.user, changes))


@api_view(["GET"])
def sync_pull(request):
    try:
        since = int(request.query_params.get("since", "0"))
    except ValueError:
        return Response({"detail": "since must be an integer"}, status=400)
    return Response(sync.pull(request.user, max(since, 0), limit=sync.PULL_LIMIT))


class ImageParser(BaseParser):
    media_type = "image/*"

    def parse(self, stream, media_type=None, parser_context=None):
        return stream.read(MAX_PHOTO_BYTES + 1)


def _photo(request, photo_id):
    try:
        return CatchPhoto.objects.get(pk=photo_id, user=request.user)
    except CatchPhoto.DoesNotExist as e:
        raise Http404 from e


@api_view(["GET", "PUT"])
@parser_classes([ImageParser])
def photo_file(request, photo_id):
    """PUT stores the image of a photo row pushed before; GET returns it."""
    photo = _photo(request, photo_id)
    if request.method == "GET":
        if not photo.has_file:
            raise Http404
        return FileResponse(default_storage.open(photo.file_name), as_attachment=False)
    content_type = request.content_type.split(";")[0].strip()
    ext = PHOTO_TYPES.get(content_type)
    if ext is None:
        return Response(status=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE)
    body = request.data
    if not body or len(body) > MAX_PHOTO_BYTES:
        return Response({"detail": "empty_or_too_large"}, status=413)
    name = f"photos/{request.user.pk}/{photo.pk}.{ext}"
    if photo.file_name and photo.file_name != name:
        default_storage.delete(photo.file_name)
    if default_storage.exists(name):
        default_storage.delete(name)
    default_storage.save(name, ContentFile(body))
    with transaction.atomic():
        photo.file_name = name
        photo.save(update_fields=["file_name"])
        sync.bump(photo)
    return Response(status=204)


@api_view(["GET", "DELETE"])
def account(request):
    """GET: everything the person stored, as JSON (LGPD/GDPR access).
    DELETE: the account and all its data, photos included, for good."""
    if request.method == "GET":
        data = sync.pull(request.user, 0, limit=10**9)
        return Response(
            {
                "email": request.user.email,
                "changes": data["changes"],
                "social": social.export(request.user, request),
            }
        )
    social.leave(request.user)
    names = list(
        CatchPhoto.objects.filter(user=request.user)
        .exclude(file_name="")
        .values_list("file_name", flat=True)
    )
    for name in names:
        default_storage.delete(name)
    request.user.delete()
    return Response(status=204)
