from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from django.utils import timezone
from datetime import timedelta
from products.models import Product, Category, ProductSearch, PriceHistory
from products.serializers import (
    ProductSerializer, PricePredictionSerializer, SearchResultSerializer,
    CategorySerializer, PriceHistorySerializer
)
from ml_engine.price_predictor import PricePredictor
from ml_engine.intent_search import IntentBasedSearcher
from ml_engine.visual_search import VisualSearchEngine
from ml_engine.models import PricePrediction
from accounts.models import ActivityLog
import json

# ============ Product Endpoints ============

@api_view(['GET'])
def product_list(request):
    """Get all products with pagination"""
    page = request.GET.get('page', 1)
    per_page = request.GET.get('per_page', 12)
    
    try:
        start = (int(page) - 1) * int(per_page)
        end = start + int(per_page)
        
        products = Product.objects.all()[start:end]
        serializer = ProductSerializer(products, many=True)
        
        return Response({
            'status': 'success',
            'total_count': Product.objects.count(),
            'page': page,
            'products': serializer.data
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['GET'])
def product_detail(request, product_id):
    """Get single product with price prediction"""
    try:
        product = get_object_or_404(Product, id=product_id)
        
        # Log view activity
        if request.user.is_authenticated:
            ActivityLog.objects.create(
                user=request.user,
                action='view',
                product=product
            )
        
        # Get latest price prediction
        prediction = PricePrediction.objects.filter(product=product).latest('prediction_date')
        prediction_serializer = PricePredictionSerializer(prediction)
        
        product_serializer = ProductSerializer(product)
        
        return Response({
            'status': 'success',
            'product': product_serializer.data,
            'price_prediction': prediction_serializer.data
        })
    except PricePrediction.DoesNotExist:
        product_serializer = ProductSerializer(product)
        return Response({
            'status': 'success',
            'product': product_serializer.data,
            'price_prediction': None
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
    """Get 7-day price prediction for product"""
    try:
        product = get_object_or_404(Product, id=product_id)
        
        # Try to get existing prediction
        prediction = PricePrediction.objects.filter(product=product).latest('prediction_date')
        
        serializer = PricePredictionSerializer(prediction)
        
        return Response({
            'status': 'success',
            'prediction': serializer.data
        })
    except PricePrediction.DoesNotExist:
        return Response(
            {'error': 'No prediction available yet', 'prediction': None},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['POST'])
def visual_search(request):
    """Search by image upload"""
    try:
        if 'image' not in request.FILES:
            return Response(
                {'error': 'Image file required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        image_file = request.FILES['image']
        
        # Extract features
        engine = VisualSearchEngine()
        features = engine.process_image_from_upload(image_file)
        
        if features is None:
            return Response(
                {'error': 'Could not process image'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Find similar products
        similar_products = engine.find_similar_products(features, top_k=10)
        
        results = [
            {
                'product': ProductSerializer(product).data,
                'similarity_score': float(score)
            }
            for product, score in similar_products
        ]
        
        return Response({
            'status': 'success',
            'results': results,
            'total_found': len(results)
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
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
