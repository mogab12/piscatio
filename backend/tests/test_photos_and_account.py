import pytest
from django.core.files.storage import default_storage

from accounts.models import User
from logbook.models import CatchPhoto, Trip
from tests.conftest import client_for
from tests.factories import catch, photo, trip

pytestmark = pytest.mark.django_db
JPEG = b"\xff\xd8\xff\xe0" + b"0" * 2000 + b"\xff\xd9"


def seed(client):
    t = trip()
    c = catch(t["id"])
    p = photo(c["id"])
    r = client.post(
        "/api/sync/push",
        {"changes": {"trips": [t], "catches": [c], "photos": [p]}},
        format="json",
    )
    assert r.status_code == 200
    # The server asks for the image of a new photo.
    assert r.json()["needs_file"] == [p["id"]]
    return p["id"]


def put(client, photo_id, body=JPEG, content_type="image/jpeg"):
    return client.generic(
        "PUT", f"/api/photos/{photo_id}/file", body, content_type=content_type
    )


def test_upload_then_download_on_another_device(client, user):
    photo_id = seed(client)
    cursor = client.get("/api/sync/pull").json()["cursor"]
    assert put(client, photo_id).status_code == 204
    # The row changes, so other devices learn the file is there.
    changed = client.get(f"/api/sync/pull?since={cursor}").json()
    assert changed["changes"]["photos"][0]["has_file"] is True
    r = client_for(user).get(f"/api/photos/{photo_id}/file")
    assert r.status_code == 200
    assert b"".join(r.streaming_content) == JPEG


def test_only_images_of_your_own_photos(client, django_user_model):
    photo_id = seed(client)
    assert put(client, photo_id, content_type="text/plain").status_code == 415
    bia = client_for(django_user_model.objects.create_user("bia@example.com"))
    assert put(bia, photo_id).status_code == 404
    assert bia.get(f"/api/photos/{photo_id}/file").status_code == 404


def test_too_large_is_refused(client, monkeypatch):
    photo_id = seed(client)
    monkeypatch.setattr("logbook.views.MAX_PHOTO_BYTES", 100)
    assert put(client, photo_id).status_code == 413


def test_export_everything(client):
    seed(client)
    data = client.get("/api/account").json()
    assert data["email"] == "ana@example.com"
    assert len(data["changes"]["trips"]) == 1
    assert len(data["changes"]["photos"]) == 1


def test_delete_account_erases_data_and_photos(client, user):
    photo_id = seed(client)
    put(client, photo_id)
    name = CatchPhoto.objects.get(pk=photo_id).file_name
    assert default_storage.exists(name)
    assert client.delete("/api/account").status_code == 204
    assert not User.objects.filter(pk=user.pk).exists()
    assert not Trip.objects.exists()
    assert not default_storage.exists(name)
    assert client.get("/api/me").status_code == 401


def test_a_photo_with_its_image_is_not_asked_again(client):
    photo_id = seed(client)
    put(client, photo_id)
    row = client.get("/api/sync/pull").json()["changes"]["photos"][0]
    r = client.post("/api/sync/push", {"changes": {"photos": [row]}}, format="json")
    assert r.json()["stale"] and r.json()["needs_file"] == []
