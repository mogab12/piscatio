import uuid
from datetime import timedelta

import pytest
from django.contrib.gis.geos import Point
from django.utils import timezone

from accounts.models import User
from billing.models import Plan, Subscription
from flags.models import FeatureFlag
from logbook.models import Bait, Catch, Trip
from venues.models import Venue, VenueMember, VenueStat

from . import factories as f
from .conftest import client_for

pytestmark = pytest.mark.django_db


def make_venue(name="Pesqueiro São José", listed=True, features=("listing",), **over):
    fields = {
        "slug": str(uuid.uuid4())[:8],
        "name": name,
        "kind": Venue.Kind.PAY_LAKE,
        "city": "Cuiabá",
        "state": "MT",
        "location": Point(-56.10, -15.60, srid=4326),
        "species": ["piaractus-mesopotamicus"],
        "status": Venue.Status.PUBLISHED if listed else Venue.Status.DRAFT,
    }
    v = Venue.objects.create(**{**fields, **over})
    if features:
        plan, _ = Plan.objects.get_or_create(
            code="-".join(features),
            defaults={"name": "Plano", "features": list(features)},
        )
        Subscription.objects.create(venue=v, plan=plan, status="active")
    return v


class TestConfig:
    def test_features_ship_off(self, client):
        r = client.get("/api/config")
        assert r.status_code == 200
        assert r.json()["features"]["venues"] is False

    def test_a_flag_can_open_to_chosen_people_or_a_share(self, client, user):
        flag = FeatureFlag.objects.get(key="venues")
        flag.enabled = True
        flag.rollout_percent = 0
        flag.save()
        assert client.get("/api/config").json()["features"]["venues"] is False
        flag.allowed_users.add(user)
        assert client.get("/api/config").json()["features"]["venues"] is True
        flag.allowed_users.clear()
        flag.rollout_percent = 100
        flag.staff_only = True
        flag.save()
        assert client.get("/api/config").json()["features"]["venues"] is False


class TestListing:
    def test_a_business_signs_up_as_a_draft_and_owns_it(self, client, user):
        r = client.post(
            "/api/venues",
            {
                "name": "Pesqueiro do Zé",
                "kind": "pay_lake",
                "city": "Cuiabá",
                "latitude": -15.6,
                "longitude": -56.1,
            },
            format="json",
        )
        assert r.status_code == 201
        v = Venue.objects.get(pk=r.json()["id"])
        assert v.status == Venue.Status.DRAFT
        assert v.slug == "pesqueiro-do-ze"
        assert VenueMember.objects.get(venue=v).role == "owner"
        # Drafts are not listed, but their owners see them.
        assert client.get("/api/venues").json()["results"] == []
        assert client.get(f"/api/venues/{v.pk}").status_code == 200
        other = client_for(User.objects.create_user("bia@example.com"))
        assert other.get(f"/api/venues/{v.pk}").status_code == 404

    def test_only_published_venues_with_a_current_plan_are_listed(self, client):
        listed = make_venue("Listado")
        make_venue("Rascunho", listed=False)
        make_venue("Sem plano", features=())
        expired = make_venue("Vencido")
        expired.subscriptions.update(
            current_period_end=timezone.now() - timedelta(days=1)
        )
        names = [v["name"] for v in client.get("/api/venues").json()["results"]]
        assert names == [listed.name]

    def test_search_by_name_without_accents_near_a_point(self, client):
        near = make_venue("Pesqueiro São José")
        make_venue("Pesqueiro Longe", location=Point(-47.9, -15.8, srid=4326))
        r = client.get("/api/venues", {"q": "sao jose", "lat": -15.6, "lon": -56.12})
        results = r.json()["results"]
        assert [v["id"] for v in results] == [str(near.pk)]
        assert results[0]["distance_km"] == pytest.approx(2.1, abs=0.3)
        assert results[0]["latitude"] == pytest.approx(-15.6)
        r = client.get("/api/venues", {"lat": -15.6, "lon": -56.12, "radius_km": 50})
        assert len(r.json()["results"]) == 1
        r = client.get("/api/venues", {"species": "salminus-brasiliensis"})
        assert r.json()["results"] == []
        # It showed up in two searches.
        assert VenueStat.objects.get(venue=near).impressions == 2

    def test_views_and_favorites(self, client):
        v = make_venue()
        assert client.get(f"/api/venues/{v.pk}").json()["is_favorite"] is False
        assert client.post(f"/api/venues/{v.pk}/favorite").status_code == 204
        assert client.get(f"/api/venues/{v.pk}").json()["is_favorite"] is True
        client.delete(f"/api/venues/{v.pk}/favorite")
        assert v.favorites.count() == 0
        # Two profile views (a favorite is not a view).
        assert VenueStat.objects.get(venue=v).views == 2

    def test_only_owners_and_managers_edit(self, client, user):
        v = make_venue()
        r = client.patch(f"/api/venues/{v.pk}", {"description": "x"}, format="json")
        assert r.status_code == 403
        VenueMember.objects.create(venue=v, user=user, role="staff")
        r = client.patch(f"/api/venues/{v.pk}", {"description": "x"}, format="json")
        assert r.status_code == 403
        VenueMember.objects.filter(venue=v).update(role="manager")
        r = client.patch(
            f"/api/venues/{v.pk}",
            {"description": "Tanques de pacu", "species": ["piaractus-mesopotamicus"]},
            format="json",
        )
        assert r.status_code == 200
        assert r.json()["description"] == "Tanques de pacu"
        mine = client.get("/api/me/venues").json()["results"]
        assert mine[0]["role"] == "manager" and mine[0]["features"] == ["listing"]


def angler_trip(venue, email, species="piaractus-mesopotamicus", share=True, bait=None):
    u = User.objects.filter(email=email).first() or User.objects.create_user(
        email, share_insights=share
    )
    now = timezone.now()
    common = {"user": u, "created_at": now, "updated_at": now, "server_seq": 1}
    t = Trip.objects.create(
        id=uuid.uuid4(),
        started_at=now.replace(month=3),
        timezone="America/Cuiaba",
        privacy_level="private",
        moon_phase="fullMoon",
        moon_illumination=1,
        venue=venue,
        **common,
    )
    b = None
    if bait:
        b = Bait.objects.create(id=uuid.uuid4(), name=bait, type="natural", **common)
    Catch.objects.create(
        id=uuid.uuid4(),
        trip=t,
        species_id=species,
        caught_at=now.replace(hour=10, minute=0),
        released=True,
        bait=b,
        **common,
    )
    return u


class TestInsights:
    def test_need_a_plan_and_a_role(self, client, user):
        v = make_venue()
        assert client.get(f"/api/venues/{v.pk}/insights").status_code == 404
        VenueMember.objects.create(venue=v, user=user, role="staff")
        assert client.get(f"/api/venues/{v.pk}/insights").status_code == 402

    def test_nothing_until_enough_people_agreed(self, client, user):
        v = make_venue(features=("listing", "insights"))
        VenueMember.objects.create(venue=v, user=user, role="owner")
        for i in range(9):
            angler_trip(v, f"a{i}@example.com")
        # Plenty of people who did not agree do not count.
        for i in range(20):
            angler_trip(v, f"no{i}@example.com", share=False)
        r = client.get(f"/api/venues/{v.pk}/insights").json()
        assert r["enough_data"] is False
        assert "species" not in r

    def test_totals_without_small_groups(self, client, user):
        v = make_venue(features=("listing", "insights"))
        VenueMember.objects.create(venue=v, user=user, role="owner")
        for i in range(12):
            angler_trip(v, f"a{i}@example.com", bait="Ração" if i < 6 else None)
        # Two people with a rare species: too few to show.
        angler_trip(v, "rare1@example.com", species="salminus-brasiliensis")
        angler_trip(v, "rare2@example.com", species="salminus-brasiliensis")
        r = client.get(f"/api/venues/{v.pk}/insights").json()
        assert r["enough_data"] is True
        assert r["anglers"] == 10  # 14, rounded down to a multiple of 5
        assert r["catches"] == 14
        assert [s["species_id"] for s in r["species"]] == ["piaractus-mesopotamicus"]
        assert r["baits"] == [{"name": "ração", "anglers": 6}]
        assert sum(r["hours"]) == 14 and r["months"][2] == 14
        assert r["released_share"] == 1


class TestTripVenue:
    def test_a_trip_remembers_its_venue(self, client):
        v = make_venue()
        t = f.trip(venue_id=str(v.pk))
        r = client.post("/api/sync/push", {"changes": {"trips": [t]}}, format="json")
        assert r.json()["accepted"]
        assert Trip.objects.get(pk=t["id"]).venue == v
        pulled = client.get("/api/sync/pull").json()["changes"]["trips"][0]
        assert pulled["venue_id"] == str(v.pk)

    def test_a_venue_that_is_gone_does_not_block_the_trip(self, client):
        t = f.trip(venue_id=str(uuid.uuid4()))
        r = client.post("/api/sync/push", {"changes": {"trips": [t]}}, format="json")
        assert r.json()["accepted"]
        assert Trip.objects.get(pk=t["id"]).venue is None


def test_the_insights_consent_is_the_persons_to_give(client, user):
    assert client.get("/api/me").json()["share_insights"] is False
    r = client.patch("/api/me", {"share_insights": True}, format="json")
    assert r.json()["share_insights"] is True
    user.refresh_from_db()
    assert user.share_insights is True
