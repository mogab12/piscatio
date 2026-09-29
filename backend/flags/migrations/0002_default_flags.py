from django.db import migrations

DEFAULTS = [
    ("venues", "Venues: search, trip venue, insights consent"),
]


def add(apps, schema_editor):
    FeatureFlag = apps.get_model("flags", "FeatureFlag")
    for key, description in DEFAULTS:
        FeatureFlag.objects.get_or_create(
            key=key, defaults={"description": description, "enabled": False}
        )


def remove(apps, schema_editor):
    apps.get_model("flags", "FeatureFlag").objects.filter(
        key__in=[k for k, _ in DEFAULTS]
    ).delete()


class Migration(migrations.Migration):
    dependencies = [("flags", "0001_initial")]
    operations = [migrations.RunPython(add, remove)]
