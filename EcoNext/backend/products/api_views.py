from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from django.shortcuts import get_object_or_404
from django.utils import timezone
from datetime import timedelta
from products.models import Product, Category, ProductSearch, PriceHistory
from products.serializers import (
    ProductSerializer, PricePredictionSerializer, SearchResultSerializer,
    CategorySerializer, PriceHistorySerializer
)
from ml_engine.price_predictor import PricePredictor, PricePredictionService
from ml_engine.visual_search import visual_search_engine
from ml_engine.models import PricePrediction
from accounts.models import ActivityLog
import json

# ============ Product Endpoints ============

from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status, viewsets
from django.shortcuts import get_object_or_404
from django.utils import timezone
from datetime import timedelta
from products.models import (
    Product, Category, ProductSearch, PriceHistory,
    SubCategory, AgeGroup, GenderCategory, EcoTag, SkinOrBodyFit, Season, Occasion
)
from products.serializers import (
    ProductSerializer, PricePredictionSerializer, SearchResultSerializer,
    CategorySerializer, PriceHistorySerializer, SubCategorySerializer,
    AgeGroupSerializer, GenderCategorySerializer, EcoTagSerializer,
    SkinOrBodyFitSerializer, SeasonSerializer, OccasionSerializer
)
from ml_engine.price_predictor import PricePredictor, PricePredictionService
from ml_engine.visual_search import visual_search_engine
from ml_engine.models import PricePrediction
from accounts.models import ActivityLog
from personalization.models import UserPreference
import json

# ============ Personalization-related ViewSets ============

class AgeGroupViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AgeGroup.objects.all()
    serializer_class = AgeGroupSerializer

class GenderCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = GenderCategory.objects.all()
    serializer_class = GenderCategorySerializer

class SubCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = SubCategory.objects.all()
    serializer_class = SubCategorySerializer

class EcoTagViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = EcoTag.objects.all()
    serializer_class = EcoTagSerializer

class SkinOrBodyFitViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = SkinOrBodyFit.objects.all()
    serializer_class = SkinOrBodyFitSerializer

class SeasonViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Season.objects.all()
    serializer_class = SeasonSerializer

class OccasionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Occasion.objects.all()
    serializer_class = OccasionSerializer

# ============ Product Endpoints ============

@api_view(['GET'])
def product_list(request):
    """Get all products with pagination and filtering"""
    page = request.GET.get('page', 1)
    per_page = request.GET.get('per_page', 12)
    
    # Filtering
    products = Product.objects.all()
    age_group = request.query_params.get('age_group')
    gender_category = request.query_params.get('gender_category')
    category = request.query_params.get('category')
    price_min = request.query_params.get('price_min')
    price_max = request.query_params.get('price_max')
    eco_tags = request.query_params.getlist('eco_tags')
    rating = request.query_params.get('rating')
    sort_by = request.query_params.get('sort_by', '-created_at')

    if age_group:
        products = products.filter(age_groups__name=age_group)
    if gender_category:
        products = products.filter(gender_categories__name=gender_category)
    if category:
        products = products.filter(category__name=category)
    if price_min:
        products = products.filter(current_price__gte=price_min)
    if price_max:
        products = products.filter(current_price__lte=price_max)
    if eco_tags:
        products = products.filter(eco_tags__name__in=eco_tags).distinct()
    if rating:
        # Assuming a 'rating' field on Product model, which is not there yet.
        # Add a 'rating' field to Product model to use this filter.
        # products = products.filter(rating__gte=rating)
        pass

    products = products.order_by(sort_by)

    try:
        start = (int(page) - 1) * int(per_page)
        end = start + int(per_page)
        
        total_count = products.count()
        products = products[start:end]
        serializer = ProductSerializer(products, many=True)
        
        return Response({
            'status': 'success',
            'total_count': total_count,
            'page': page,
            'products': serializer.data
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )

from personalization.recommendations import RecommendationService

@api_view(['GET'])
def personalized_recommendations(request):
    """Get personalized product recommendations for the logged-in user."""
    if not request.user.is_authenticated:
        return Response(
            {'error': 'Authentication required'},
            status=status.HTTP_401_UNAUTHORIZED
        )

    try:
        recommendation_service = RecommendationService(request.user)
        recommendations = recommendation_service.get_recommendations()
        
        serializer = ProductSerializer(recommendations, many=True)
        return Response({
            'status': 'success',
            'recommendations': serializer.data
        })

    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )



@api_view(['GET'])
def product_detail(request, product_id):
    """Get single product with live price prediction"""
    try:
        product = get_object_or_404(Product, id=product_id)
        
        # Log view activity
        if request.user.is_authenticated:
            ActivityLog.objects.create(
                user=request.user,
                action='view',
                product=product
            )
        
        # Compute live prediction
        service = PricePredictionService()
        prediction_data = service.predict(product, use_cache=True)
        
        product_serializer = ProductSerializer(product)
        
        return Response({
            'status': 'success',
            'product': product_serializer.data,
            'price_prediction': prediction_data
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


# ============ Search Endpoints ============

@api_view(['GET'])
def intent_search(request):
    """Smart intent-based search"""
    query = request.GET.get('q', '').strip()
    
    if not query:
        return Response(
            {'error': 'Search query required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        # Log search
        ProductSearch.objects.create(query=query)
        
        # Perform search
        searcher = IntentBasedSearcher()
        categories = searcher.get_category_recommendations(query)
        
        results = {}
        for category, products_data in categories.items():
            results[category] = SearchResultSerializer(products_data, many=True).data
        
        return Response({
            'status': 'success',
            'query': query,
            'results': results,
            'total_found': sum(len(v) for v in results.values())
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['GET'])
def category_browse(request):
    """Browse by category"""
    category_id = request.GET.get('id')
    
    try:
        if category_id:
            category = get_object_or_404(Category, id=category_id)
            products = category.products.all()
        else:
            products = Product.objects.all()
        
        serializer = ProductSerializer(products, many=True)
        
        return Response({
            'status': 'success',
            'products': serializer.data
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


# ============ ML Endpoints ============

@api_view(['GET'])
def price_prediction(request, product_id):
    """Get 7-day price prediction for product — computed live with caching."""
    try:
        product = get_object_or_404(Product, id=product_id)

        service = PricePredictionService()
        result = service.predict(product, use_cache=True)

        return Response({
            'status': 'success',
            'prediction': result
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['POST'])
@permission_classes([AllowAny])
def visual_search(request):
    """Search by image upload"""
    if 'image' not in request.FILES:
        return Response(
            {'status': 'error', 'message': 'Image file not provided.'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    image_file = request.FILES['image']

    try:
        # Use the instantiated engine to find similar products
        similar_products = visual_search_engine.search(image_file, top_k=10)
        
        # Serialize the results
        results = [
            {
                'product': ProductSerializer(item['product']).data,
                'similarity_score': float(item['similarity_score'])
            }
            for item in similar_products
        ]
        
        return Response({
            'status': 'success',
            'results': results,
            'total_found': len(results)
        })
    except Exception as e:
        return Response(
            {'status': 'error', 'message': f'An error occurred: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
def trending_now(request):
    """Get trending products"""
    try:
        from site_analytics.models import TrendingProduct
        
        trending = TrendingProduct.objects.filter(
            timestamp__gte=timezone.now() - timedelta(hours=1)
        ).order_by('rank')[:10]
        
        results = [
            {
                'product': ProductSerializer(t.product).data,
                'rank': t.rank,
                'views': t.views_count,
                'searches': t.searches_count,
                'purchases': t.purchase_count
            }
            for t in trending
        ]
        
        return Response({
            'status': 'success',
            'trending_products': results
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


# ============ Analytics Endpoints ============

@api_view(['GET'])
def search_history(request):
    """Get trending search queries"""
    try:
        from django.db.models import Count
        from datetime import timedelta
        from django.utils import timezone
        
        cutoff = timezone.now() - timedelta(days=7)
        trending_searches = ProductSearch.objects.filter(
            timestamp__gte=cutoff
        ).values('query').annotate(
            count=Count('id')
        ).order_by('-count')[:20]
        
        return Response({
            'status': 'success',
            'trending_searches': list(trending_searches)
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )
