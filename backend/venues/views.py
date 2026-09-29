from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.geos import Point
from django.contrib.gis.measure import D
from django.db import IntegrityError
from django.db.models import Q
from django.http import Http404
from django.utils.text import slugify
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response

from billing.models import entitlements

from . import insights as venue_insights
from .models import Venue, VenueFavorite, VenueMember, count
from .serializers import VenueSerializer, VenueWriteSerializer

SEARCH_LIMIT = 50
MAX_OWNED = 5


def _float(request, name, limit):
    try:
        value = float(request.query_params[name])
    except (KeyError, ValueError):
        return None
    return value if -limit <= value <= limit else None


def _favorites(user, venues):
    return set(
        VenueFavorite.objects.filter(user=user, venue__in=venues).values_list(
            "venue_id", flat=True
        )
    )


def _member(user, venue) -> VenueMember | None:
    return VenueMember.objects.filter(user=user, venue=venue).first()


def _visible(request, venue_id) -> Venue:
    """Listed venues for everyone; drafts only for their own people."""
    venue = Venue.objects.filter(pk=venue_id).first()
    if venue is None:
        raise Http404
    listed = Venue.objects.listed().filter(pk=venue.pk).exists()
    if (
        not listed
        and _member(request.user, venue) is None
        and not request.user.is_staff
    ):
        raise Http404
    return venue


@api_view(["GET", "POST"])
def venues(request):
    if request.method == "POST":
        return _create(request)
    qs = Venue.objects.listed()
    q = (request.query_params.get("q") or "").strip()[:80]
    if q:
        qs = qs.filter(Q(name__unaccent__icontains=q) | Q(city__unaccent__icontains=q))
    kind = request.query_params.get("kind")
    if kind:
        qs = qs.filter(kind=kind)
    species = request.query_params.get("species")
    if species:
        qs = qs.filter(species__contains=[species])
    lat, lon = _float(request, "lat", 90), _float(request, "lon", 180)
    if lat is not None and lon is not None:
        here = Point(lon, lat, srid=4326)
        try:
            radius = min(max(float(request.query_params.get("radius_km", 100)), 1), 500)
        except ValueError:
            radius = 100
        qs = (
            qs.filter(location__distance_lte=(here, D(km=radius)))
            .annotate(distance=Distance("location", here))
            .order_by("distance")
        )
    else:
        qs = qs.order_by("-verified", "name")
    found = list(qs[:SEARCH_LIMIT])
    count([v.pk for v in found], "impressions")
    data = VenueSerializer(
        found, many=True, context={"favorites": _favorites(request.user, found)}
    ).data
    return Response({"results": data})


def _create(request):
    """A business signs up: the venue starts as a draft, its creator as the
    owner. Staff verifies and it is listed once a plan is active."""
    owned = VenueMember.objects.filter(
        user=request.user, role=VenueMember.Role.OWNER
    ).count()
    if owned >= MAX_OWNED:
        return Response({"detail": "too_many_venues"}, status=400)
    data = VenueWriteSerializer(data=request.data)
    data.is_valid(raise_exception=True)
    base = slugify(data.validated_data["name"])[:70] or "local"
    slug, n = base, 1
    while Venue.objects.filter(slug=slug).exists():
        n += 1
        slug = f"{base}-{n}"
    try:
        venue = data.save(slug=slug)
    except IntegrityError:
        return Response({"detail": "try_again"}, status=409)
    VenueMember.objects.create(
        venue=venue, user=request.user, role=VenueMember.Role.OWNER
    )
    return Response(VenueSerializer(venue).data, status=status.HTTP_201_CREATED)


@api_view(["GET", "PATCH"])
def venue(request, venue_id):
    v = _visible(request, venue_id)
    if request.method == "PATCH":
        member = _member(request.user, v)
        if member is None or not member.can_edit:
            return Response({"detail": "not_allowed"}, status=403)
        data = VenueWriteSerializer(v, data=request.data, partial=True)
        data.is_valid(raise_exception=True)
        v = data.save()
    else:
        count([v.pk], "views")
    return Response(
        VenueSerializer(v, context={"favorites": _favorites(request.user, [v])}).data
    )


@api_view(["POST", "DELETE"])
def favorite(request, venue_id):
    v = _visible(request, venue_id)
    if request.method == "POST":
        VenueFavorite.objects.get_or_create(venue=v, user=request.user)
    else:
        VenueFavorite.objects.filter(venue=v, user=request.user).delete()
    return Response(status=204)


@api_view(["GET"])
def insights(request, venue_id):
    """For the venue's own people, when its plan includes insights."""
    v = Venue.objects.filter(pk=venue_id).first()
    member = _member(request.user, v) if v else None
    if v is None or member is None:
        raise Http404
    if "insights" not in entitlements(v):
        return Response({"detail": "plan_required"}, status=402)
    return Response(venue_insights.insights(v))


@api_view(["GET"])
def my_venues(request):
    """The venues this person helps run, with their role and features."""
    roles = VenueMember.objects.filter(user=request.user).select_related("venue")
    return Response(
        {
            "results": [
                {
                    "venue": VenueSerializer(m.venue).data,
                    "role": m.role,
                    "status": m.venue.status,
                    "features": sorted(entitlements(m.venue)),
                }
                for m in roles
            ]
        }
    )
