from django.conf import settings
from rest_framework.decorators import api_view
from rest_framework.response import Response

from .models import flags_for


@api_view(["GET"])
def config(request):
    """What this account may use, and the oldest app build still served."""
    return Response(
        {
            "features": flags_for(request.user),
            "min_app_build": settings.MIN_APP_BUILD,
        }
    )
