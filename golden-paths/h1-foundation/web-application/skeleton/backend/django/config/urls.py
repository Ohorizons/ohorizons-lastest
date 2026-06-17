"""URL configuration for ${{ values.appName }}."""

from django.http import JsonResponse
from django.urls import path


def health(request):
    return JsonResponse({"status": "healthy"})


def list_items(request):
    return JsonResponse({"items": []})


urlpatterns = [
    path("health", health),
    path("api/items", list_items),
]
