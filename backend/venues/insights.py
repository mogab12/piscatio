"""What a venue learns about the anglers who fish there: only totals, only
from people who agreed to share (`User.share_insights`), only once enough
different people are in the pool, and only groups big enough that no one
can be picked out."""

from collections import Counter, defaultdict
from datetime import timedelta
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from django.conf import settings
from django.db.models import Sum
from django.utils import timezone

from logbook.models import Catch, Trip

from .models import Venue


def _min_anglers() -> int:
    return settings.VENUE_INSIGHTS_MIN_ANGLERS


def _min_group() -> int:
    return settings.VENUE_INSIGHTS_MIN_GROUP


def _local_hour(moment, tz_name: str) -> int:
    try:
        return moment.astimezone(ZoneInfo(tz_name)).hour
    except (ZoneInfoNotFoundError, ValueError):
        return moment.hour


def audience(venue: Venue) -> dict:
    """Views, search appearances and favorites of the last 30 days."""
    since = timezone.localdate() - timedelta(days=30)
    totals = venue.stats.filter(day__gte=since).aggregate(
        views=Sum("views"), impressions=Sum("impressions")
    )
    return {
        "views_30d": totals["views"] or 0,
        "impressions_30d": totals["impressions"] or 0,
        "favorites": venue.favorites.count(),
    }


def insights(venue: Venue) -> dict:
    trips = Trip.objects.filter(
        venue=venue, deleted_at__isnull=True, user__share_insights=True
    )
    anglers = trips.values("user").distinct().count()
    result = {"audience": audience(venue), "min_anglers": _min_anglers()}
    if anglers < _min_anglers():
        return {**result, "enough_data": False}

    catches = list(
        Catch.objects.filter(trip__in=trips, deleted_at__isnull=True)
        .select_related("trip", "bait")
        .only(
            "species_id",
            "caught_at",
            "released",
            "user_id",
            "trip__timezone",
            "bait__name",
        )
    )
    species_anglers = defaultdict(set)
    species_catches = Counter()
    bait_anglers = defaultdict(set)
    hours = [0] * 24
    released = informed = 0
    for c in catches:
        if c.species_id:
            species_anglers[c.species_id].add(c.user_id)
            species_catches[c.species_id] += 1
        if c.bait is not None:
            name = " ".join(c.bait.name.lower().split())
            if name:
                bait_anglers[name].add(c.user_id)
        hours[_local_hour(c.caught_at, c.trip.timezone)] += 1
        if c.released is not None:
            informed += 1
            released += c.released
    months = [0] * 12
    for t in trips.only("started_at"):
        months[t.started_at.month - 1] += 1

    group = _min_group()
    return {
        **result,
        "enough_data": True,
        # Rounded down: small changes do not reveal one person.
        "anglers": anglers - anglers % 5,
        "trips": trips.count(),
        "catches": len(catches),
        "species": [
            {"species_id": s, "catches": n}
            for s, n in species_catches.most_common()
            if len(species_anglers[s]) >= group
        ],
        "baits": [
            {"name": name, "anglers": len(people)}
            for name, people in sorted(bait_anglers.items(), key=lambda kv: -len(kv[1]))
            if len(people) >= group
        ][:10],
        "hours": hours,
        "months": months,
        "released_share": released / informed if informed else None,
    }
