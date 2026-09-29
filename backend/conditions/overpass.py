"""The app's OpenStreetMap query (see app/lib/domain/services/overpass_map.dart),
run by the server so the public Overpass service sees one client, cached."""

import math

HALF_SIZE_M = 14000.0
STREAM_HALF_SIZE_M = 9000.0


def _bbox(lat: float, lng: float, half: float) -> str:
    kx = 111320 * math.cos(math.radians(lat))
    ky = 110574
    south, north = lat - half / ky, lat + half / ky
    west, east = lng - half / kx, lng + half / kx
    return f"{south:.5f},{west:.5f},{north:.5f},{east:.5f}"


def query(lat: float, lng: float) -> str:
    b = _bbox(lat, lng, HALF_SIZE_M)
    s = _bbox(lat, lng, STREAM_HALF_SIZE_M)
    return (
        "[out:json][timeout:25][maxsize:67108864];("
        f'way["natural"="water"]({b});'
        f'relation["natural"="water"]({b});'
        f'way["waterway"="riverbank"]({b});'
        f'relation["waterway"="riverbank"]({b});'
        f'way["landuse"="reservoir"]({b});'
        f'relation["landuse"="reservoir"]({b});'
        f'way["waterway"~"^(river|canal)$"]({b});'
        f'way["waterway"="stream"]({s});'
        f'way["natural"="coastline"]({b});'
        f'way["highway"~"^(motorway|trunk|primary|secondary)$"]({b});'
        ");out geom qt;"
    )
