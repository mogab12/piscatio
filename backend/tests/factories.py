import uuid
from datetime import UTC, datetime, timedelta

BASE = datetime(2026, 9, 12, 9, 0, tzinfo=UTC)


def iso(dt: datetime) -> str:
    return dt.isoformat().replace("+00:00", "Z")


def trip(**over):
    t = BASE
    row = {
        "id": str(uuid.uuid4()),
        "created_at": iso(t),
        "updated_at": iso(t),
        "deleted_at": None,
        "started_at": iso(t),
        "ended_at": iso(t + timedelta(hours=3)),
        "timezone": "America/Cuiaba",
        "latitude": -16.52,
        "longitude": -56.41,
        "location_accuracy_m": 8.0,
        "location_name": "Poço do Dourado",
        "location_region": "Cuiabá, MT",
        "privacy_level": "approximate",
        "moon_phase": "waxingGibbous",
        "moon_illumination": 0.68,
        "notes": None,
        "is_retroactive": False,
    }
    return {**row, **over}


def catch(trip_id, **over):
    t = BASE + timedelta(hours=1)
    row = {
        "id": str(uuid.uuid4()),
        "created_at": iso(t),
        "updated_at": iso(t),
        "deleted_at": None,
        "trip_id": trip_id,
        "species_id": "salminus-brasiliensis",
        "caught_at": iso(t),
        "weight_g": 4200,
        "length_mm": 720,
        "released": True,
        "bait_id": None,
        "gear_id": None,
        "depth_mm": None,
        "latitude": None,
        "longitude": None,
        "notes": None,
    }
    return {**row, **over}


def photo(catch_id, **over):
    t = BASE + timedelta(hours=1)
    row = {
        "id": str(uuid.uuid4()),
        "created_at": iso(t),
        "updated_at": iso(t),
        "deleted_at": None,
        "catch_id": catch_id,
        "width": 1200,
        "height": 1600,
        "taken_at": iso(t),
        "sort_order": 0,
    }
    return {**row, **over}


def later(row, minutes=5, **over):
    t = datetime.fromisoformat(row["updated_at"].replace("Z", "+00:00"))
    return {**row, "updated_at": iso(t + timedelta(minutes=minutes)), **over}
