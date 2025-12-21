"""
Core views for app.
"""
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.shortcuts import render


@api_view(['GET'])
def health_check(request):
    """Returns successful response."""
    return Response({'healthy': True})


def landing_page(request):
    """Landing page view."""
    return render(request, 'core/landing.html')
