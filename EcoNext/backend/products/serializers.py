from rest_framework import serializers
from products.models import Product, Category, PriceHistory, ProductSearch
from accounts.models import UserProfile, ActivityLog
from shop_cart.models import Cart, CartItem
from order_service.models import Order, OrderItem
from ml_engine.models import PricePrediction

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'description']


class ProductSerializer(serializers.ModelSerializer):
    category = CategorySerializer()
    
    class Meta:
        model = Product
        fields = ['id', 'name', 'description', 'category', 'current_price', 'image_url', 'stock', 'tags', 'created_at']


class PriceHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = PriceHistory
        fields = ['price', 'date']


class PricePredictionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PricePrediction
        fields = [
            'id', 'product', 'prediction_date', 'day1_price', 'day2_price',
            'day3_price', 'day4_price', 'day5_price', 'day6_price', 'day7_price',
            'price_change', 'recommendation', 'confidence_score'
        ]


class CartItemSerializer(serializers.ModelSerializer):
    product = ProductSerializer()
    subtotal = serializers.SerializerMethodField()
    
    class Meta:
        model = CartItem
        fields = ['id', 'product', 'quantity', 'subtotal', 'added_at']
    
    def get_subtotal(self, obj):
        return str(obj.get_subtotal())


class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True)
    total = serializers.SerializerMethodField()
    
    class Meta:
        model = Cart
        fields = ['id', 'items', 'total', 'created_at', 'updated_at']
    
    def get_total(self, obj):
        return str(obj.get_total())


class OrderItemSerializer(serializers.ModelSerializer):
    product = ProductSerializer()
    subtotal = serializers.SerializerMethodField()
    
    class Meta:
        model = OrderItem
        fields = ['id', 'product', 'quantity', 'price_at_purchase', 'subtotal']
    
    def get_subtotal(self, obj):
        return str(obj.get_subtotal())


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True)
    
    class Meta:
        model = Order
        fields = [
            'id', 'user', 'status', 'total_price', 'shipping_address',
            'city', 'state', 'zipcode', 'country', 'items', 'created_at'
        ]


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = ['phone', 'address', 'city', 'state', 'zipcode', 'country', 'preferences']


class ActivityLogSerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)
    
    class Meta:
        model = ActivityLog
        fields = ['id', 'action', 'product', 'details', 'timestamp']


class SearchResultSerializer(serializers.Serializer):
    product = ProductSerializer()
    similarity_score = serializers.FloatField()
    intent_match = serializers.CharField()
