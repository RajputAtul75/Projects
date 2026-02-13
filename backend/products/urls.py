from django.urls import path
from . import api_views
from .views import test

urlpatterns = [
    # Test endpoint
    path("test/", test),
    
    # Product endpoints
    path("", api_views.product_list, name="product_list"),
    path("<int:product_id>/", api_views.product_detail, name="product_detail"),
    
    # Search endpoints
    path("search/intent/", api_views.intent_search, name="intent_search"),
    path("search/visual/", api_views.visual_search, name="visual_search"),
    path("categories/", api_views.category_browse, name="category_browse"),
    
    # ML endpoints
    path("<int:product_id>/prediction/", api_views.price_prediction, name="price_prediction"),
    path("trending/", api_views.trending_now, name="trending_now"),
    
    # Analytics
    path("search/trending/", api_views.search_history, name="search_history"),
]
