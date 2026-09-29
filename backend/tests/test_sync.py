import pytest

from logbook import sync
from logbook.models import Catch, Trip
from tests.conftest import client_for
from tests.factories import catch, later, photo, trip

pytestmark = pytest.mark.django_db


def push(client, **changes):
    r = client.post("/api/sync/push", {"changes": changes}, format="json")
    assert r.status_code == 200, r.content
    return r.json()


def pull(client, since=0):
    r = client.get(f"/api/sync/pull?since={since}")
    assert r.status_code == 200
    return r.json()


def test_push_then_pull_on_another_device(client, user):
    t = trip()
    c = catch(t["id"])
    p = photo(c["id"])
    # Children before parents in the request: the server orders them.
    result = push(client, photos=[p], catches=[c], trips=[t])
    assert len(result["accepted"]) == 3 and not result["rejected"]

    other = client_for(user)
    data = pull(other)
    assert [r["id"] for r in data["changes"]["trips"]] == [t["id"]]
    got = data["changes"]["trips"][0]
    assert (got["latitude"], got["longitude"]) == (-16.52, -56.41)
    assert got["location_name"] == "Poço do Dourado"
    assert data["changes"]["catches"][0]["trip_id"] == t["id"]
    assert data["changes"]["photos"][0]["has_file"] is False
    assert pull(other, data["cursor"])["changes"]["trips"] == []


def test_last_write_wins(client):
    t = trip()
    push(client, trips=[t])
    newer = later(t, notes="Chuva forte")
    assert push(client, trips=[newer])["accepted"]
    # An edit made earlier (on an offline phone) loses.
    older = later(t, minutes=1, notes="Sol")
    assert push(client, trips=[older])["stale"]
    assert Trip.objects.get(pk=t["id"]).notes == "Chuva forte"


def test_deletions_travel_as_tombstones(client):
    t = trip()
    push(client, trips=[t])
    cursor = pull(client)["cursor"]
    gone = later(t, deleted_at=later(t)["updated_at"])
    push(client, trips=[gone])
    data = pull(client, cursor)
    assert data["changes"]["trips"][0]["deleted_at"] is not None
    assert Trip.objects.filter(pk=t["id"]).exists()


def test_rows_of_someone_else_are_off_limits(client, django_user_model):
    t = trip()
    push(client, trips=[t])
    bia = client_for(django_user_model.objects.create_user("bia@example.com"))
    result = push(bia, trips=[later(t, notes="mine now")])
    assert result["rejected"][0]["errors"] == "not_yours"
    # Nor can she hang a catch on it.
    result = push(bia, catches=[catch(t["id"])])
    assert result["rejected"]
    assert pull(bia)["changes"]["trips"] == []
    assert Catch.objects.count() == 0


def test_invalid_rows_are_rejected_one_by_one(client):
    good = trip()
    bad = trip(latitude=123)
    no_trip = catch("0192f7a0-0000-7000-8000-000000000000")
    result = push(client, trips=[good, bad], catches=[no_trip])
    assert [a["id"] for a in result["accepted"]] == [good["id"]]
    assert {r["id"] for r in result["rejected"]} == {bad["id"], no_trip["id"]}


def test_pull_pages_in_order(client, monkeypatch):
    rows = [trip() for _ in range(7)]
    push(client, trips=rows)
    monkeypatch.setattr(sync, "PULL_LIMIT", 3)
    seen, cursor, more = [], 0, True
    while more:
        r = client.get(f"/api/sync/pull?since={cursor}").json()
        seen += [t["id"] for t in r["changes"]["trips"]]
        cursor, more = r["cursor"], r["more"]
    assert sorted(seen) == sorted(t["id"] for t in rows)
    assert len(seen) == len(set(seen))


def test_custom_species_with_names(client):
    s = {
        **trip(),
        "scientific_name": "Brycon hilarii",
        "habitats": "freshwater",
        "region_tags": "SA",
        "names": [{"lang": "pt", "name": "Piraputanga", "is_primary": True}],
    }
    for k in (
        "started_at",
        "ended_at",
        "timezone",
        "latitude",
        "longitude",
        "location_accuracy_m",
        "location_name",
        "location_region",
        "privacy_level",
        "moon_phase",
        "moon_illumination",
        "notes",
        "is_retroactive",
    ):
        s.pop(k)
    assert push(client, species=[s])["accepted"]
    got = pull(client)["changes"]["species"][0]
    assert got["names"][0]["name"] == "Piraputanga"


def test_too_big_a_push_is_refused(client, monkeypatch):
    monkeypatch.setattr(sync, "MAX_PUSH_ROWS", 2)
    r = client.post(
        "/api/sync/push",
        {"changes": {"trips": [trip(), trip(), trip()]}},
        format="json",
    )
    assert r.status_code == 413
