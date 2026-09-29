"""Conditions the app shows live: current weather (MET Norway) and map data
(OpenStreetMap). Only for signed-in users: this is not an open proxy."""

from datetime import timedelta

import requests
from django.conf import settings
from django.core.cache import cache
from django.http import HttpResponse
from django.utils import timezone
from rest_framework.decorators import api_view
from rest_framework.response import Response

from . import overpass
from .models import MapArea

MET_URL = "https://api.met.no/weatherapi/locationforecast/2.0/compact"
MAP_TTL = timedelta(days=90)


def _coord(request, name, limit):
    try:
        value = float(request.query_params[name])
    except (KeyError, ValueError):
        return None
    return value if -limit <= value <= limit else None


@api_view(["GET"])
def weather_now(request):
    """Weather right now near a point. The point is rounded to ~1 km before
    it leaves our server (MET asks for at most 4 decimals; 2 also keeps the
    spot private and makes the cache useful)."""
    lat = _coord(request, "lat", 90)
    lon = _coord(request, "lon", 180)
    if lat is None or lon is None:
        return Response({"detail": "lat and lon are required"}, status=400)
    lat, lon = round(lat, 2), round(lon, 2)
    key = f"met:{lat}:{lon}"
    data = cache.get(key)
    if data is None:
        try:
            r = requests.get(
                MET_URL,
                params={"lat": lat, "lon": lon},
                headers={"User-Agent": settings.MET_USER_AGENT},
                timeout=10,
            )
        except requests.RequestException:
            return Response({"detail": "weather_unavailable"}, status=503)
        if r.status_code != 200:
            return Response({"detail": "weather_unavailable"}, status=503)
        data = _current(r.json())
        cache.set(key, data, 600)
    return Response(data)


def _current(body: dict) -> dict:
    series = body["properties"]["timeseries"]
    now = timezone.now()
    # The first step at or after the current hour.
    step = next(
        (s for s in series if s["time"] >= now.strftime("%Y-%m-%dT%H:00:00Z")),
        series[0],
    )
    details = step["data"]["instant"]["details"]
    next_hour = step["data"].get("next_1_hours", {})
    wind_ms = details.get("wind_speed")
    return {
        "time": step["time"],
        "temperature_c": details.get("air_temperature"),
        "pressure_hpa": details.get("air_pressure_at_sea_level"),
        "humidity_pct": details.get("relative_humidity"),
        "cloud_pct": details.get("cloud_area_fraction"),
        "wind_speed_kmh": None if wind_ms is None else round(wind_ms * 3.6, 1),
        "wind_from_deg": details.get("wind_from_direction"),
        "precipitation_next_hour_mm": next_hour.get("details", {}).get(
            "precipitation_amount"
        ),
        "symbol": next_hour.get("summary", {}).get("symbol_code"),
        "source": "MET Norway",
    }


@api_view(["GET"])
def map_area(request):
    """Overpass answer (raw JSON) for the area around an approximate point.
    The app sends that point, never the spot."""
    lat = _coord(request, "lat", 90)
    lon = _coord(request, "lon", 180)
    if lat is None or lon is None:
        return Response({"detail": "lat and lon are required"}, status=400)
    key = f"{lat:.5f},{lon:.5f}"
    area = MapArea.objects.filter(key=key).first()
    if area is None or timezone.now() - area.fetched_at > MAP_TTL:
        try:
            r = requests.post(
                settings.OVERPASS_URL,
                data={"data": overpass.query(lat, lon)},
                headers={"User-Agent": settings.MET_USER_AGENT},
                timeout=60,
            )
        except requests.RequestException:
            return Response({"detail": "map_unavailable"}, status=503)
        if r.status_code != 200:
            return Response({"detail": "map_unavailable"}, status=503)
        area, _ = MapArea.objects.update_or_create(
            key=key, defaults={"body": r.content}
        )
    return HttpResponse(bytes(area.body), content_type="application/json")
