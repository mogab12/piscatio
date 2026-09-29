# The API with GeoDjango's system libraries (GDAL, GEOS).
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends gdal-bin libgeos-c1v5 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
RUN DJANGO_SECRET_KEY=build-only python manage.py collectstatic --noinput

EXPOSE 8000
# Migrations run at start: the database is only reachable at run time.
CMD ["sh", "-c", "python manage.py migrate --noinput && exec gunicorn piscatio.wsgi --bind 0.0.0.0:${PORT:-8000} --workers 2 --timeout 90"]
