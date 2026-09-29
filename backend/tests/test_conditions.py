import pytest
import responses
from django.utils import timezone

from conditions.models import MapArea
from conditions.views import MET_URL

pytestmark = pytest.mark.django_db


def met_body():
    hour = timezone.now().strftime("%Y-%m-%dT%H:00:00Z")
    return {
        "properties": {
            "timeseries": [
                {
                    "time": hour,
                    "data": {
                        "instant": {
                            "details": {
                                "air_temperature": 24.3,
                                "air_pressure_at_sea_level": 1012.1,
                                "relative_humidity": 71,
                                "cloud_area_fraction": 20,
                                "wind_speed": 2.5,
                                "wind_from_direction": 135,
                            }
                        },
                        "next_1_hours": {
                            "summary": {"symbol_code": "partlycloudy_day"},
                            "details": {"precipitation_amount": 0.0},
                        },
                    },
                }
            ]
        }
    }


@responses.activate
def test_weather_now_rounds_the_point_and_caches(client, settings):
    responses.get(MET_URL, json=met_body())
    r = client.get("/api/conditions/weather?lat=-16.52345&lon=-56.41234")
    assert r.status_code == 200
    data = r.json()
    assert data["temperature_c"] == 24.3
    assert data["wind_speed_kmh"] == 9.0
    assert data["source"] == "MET Norway"
    sent = responses.calls[0].request
    assert "lat=-16.52" in sent.url and "lon=-56.41" in sent.url
    assert sent.headers["User-Agent"] == settings.MET_USER_AGENT
    client.get("/api/conditions/weather?lat=-16.5211&lon=-56.4089")
    assert len(responses.calls) == 1


@responses.activate
def test_weather_unavailable(client):
    responses.get(MET_URL, status=500)
    assert client.get("/api/conditions/weather?lat=1&lon=2").status_code == 503
    assert client.get("/api/conditions/weather?lat=95&lon=2").status_code == 400


def test_conditions_need_an_account(api):
    assert api.get("/api/conditions/weather?lat=1&lon=2").status_code == 401
    assert api.get("/api/conditions/map?lat=1&lon=2").status_code == 401


@responses.activate
def test_map_area_is_fetched_once_per_area(client, settings):
    responses.post(settings.OVERPASS_URL, body=b'{"elements": []}')
    r = client.get("/api/conditions/map?lat=-16.51234&lon=-56.40321")
    assert r.status_code == 200
    assert r.json() == {"elements": []}
    body = responses.calls[0].request.body
    assert "natural%22%3D%22water" in body or 'natural"="water' in body
    client.get("/api/conditions/map?lat=-16.51234&lon=-56.40321")
    assert len(responses.calls) == 1
    assert MapArea.objects.count() == 1


def test_health_answers_over_plain_http_behind_the_proxy(api, settings):
    # The platform's health check does not go through TLS; everything else
    # is sent to HTTPS.
    settings.SECURE_SSL_REDIRECT = True
    assert api.get("/health").status_code == 200
    assert api.get("/api/me").status_code == 301
    assert api.get("/api/me", HTTP_X_FORWARDED_PROTO="https").status_code == 401
