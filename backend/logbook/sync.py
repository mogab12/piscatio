"""Offline-first sync: each device pushes the rows it changed and pulls the
rows changed elsewhere since its cursor.

- Conflicts: last write wins by the row's own `updated_at` (set by the
  device that edited it).
- Deletions: rows are never removed, `deleted_at` travels like any edit.
- Order: every accepted write takes the next `server_seq`. A person's
  pushes run one at a time (row lock on the user), so for any one person
  the sequence follows commit order and a pull never skips a row.
"""

from django.db import connection, transaction

from accounts.models import User

from .models import Bait, Catch, CatchPhoto, CustomSpecies, Gear, Trip
from .serializers import (
    BaitSerializer,
    CatchPhotoSerializer,
    CatchSerializer,
    CustomSpeciesSerializer,
    GearSerializer,
    TripSerializer,
)

# Parents before children, so references resolve within one push.
TABLES = {
    "trips": (Trip, TripSerializer),
    "baits": (Bait, BaitSerializer),
    "gear": (Gear, GearSerializer),
    "species": (CustomSpecies, CustomSpeciesSerializer),
    "catches": (Catch, CatchSerializer),
    "photos": (CatchPhoto, CatchPhotoSerializer),
}

MAX_PUSH_ROWS = 2000
PULL_LIMIT = 500


def next_seq() -> int:
    with connection.cursor() as cursor:
        cursor.execute("SELECT nextval('logbook_sync_seq')")
        return cursor.fetchone()[0]


def bump(obj) -> None:
    """Marks a row as changed on the server (e.g. its photo arrived)."""
    obj.server_seq = next_seq()
    obj.save(update_fields=["server_seq"])


def push(user: User, changes: dict) -> dict:
    accepted, stale, rejected = [], [], []
    with transaction.atomic():
        User.objects.select_for_update().get(pk=user.pk)
        for table, (model, serializer_class) in TABLES.items():
            for raw in changes.get(table) or []:
                row_id = raw.get("id") if isinstance(raw, dict) else None
                serializer = serializer_class(data=raw, context={"user": user})
                if not serializer.is_valid():
                    rejected.append(
                        {"table": table, "id": row_id, "errors": serializer.errors}
                    )
                    continue
                data = dict(serializer.validated_data)
                existing = model.objects.filter(pk=data["id"]).first()
                if existing is not None and existing.user_id != user.pk:
                    rejected.append(
                        {"table": table, "id": row_id, "errors": "not_yours"}
                    )
                    continue
                if existing is not None and existing.updated_at >= data["updated_at"]:
                    stale.append({"table": table, "id": row_id})
                    continue
                obj = existing or model(user=user)
                nested = {k: data.pop(k) for k in ("names",) if k in data}
                for field, value in {**data, **nested}.items():
                    setattr(obj, field, value)
                obj.server_seq = next_seq()
                obj.save()
                accepted.append({"table": table, "id": row_id})
        # Photo rows the server has no image for yet: the device uploads them.
        photo_ids = [r["id"] for r in accepted + stale if r["table"] == "photos"]
        needs_file = [
            str(pk)
            for pk in CatchPhoto.objects.filter(
                user=user, pk__in=photo_ids, file_name=""
            ).values_list("pk", flat=True)
        ]
    return {
        "accepted": accepted,
        "stale": stale,
        "rejected": rejected,
        "needs_file": needs_file,
    }


def pull(user: User, since: int, limit: int = PULL_LIMIT) -> dict:
    rows = []
    for table, (model, _) in TABLES.items():
        qs = model.objects.filter(user=user, server_seq__gt=since).order_by(
            "server_seq"
        )[: limit + 1]
        rows.extend((obj.server_seq, table, obj) for obj in qs)
    rows.sort(key=lambda r: r[0])
    more = len(rows) > limit
    rows = rows[:limit]
    changes = {table: [] for table in TABLES}
    for _, table, obj in rows:
        changes[table].append(TABLES[table][1](obj, context={"user": user}).data)
    return {
        "changes": changes,
        "cursor": rows[-1][0] if rows else since,
        "more": more,
    }


def count_rows(changes: dict) -> int:
    return sum(len(v or []) for v in changes.values() if isinstance(v, list))
