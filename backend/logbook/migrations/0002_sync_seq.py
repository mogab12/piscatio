from django.db import migrations


class Migration(migrations.Migration):
    dependencies = [("logbook", "0001_initial")]

    operations = [
        migrations.RunSQL(
            "CREATE SEQUENCE IF NOT EXISTS logbook_sync_seq",
            "DROP SEQUENCE IF EXISTS logbook_sync_seq",
        )
    ]
