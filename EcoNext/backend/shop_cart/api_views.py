from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from shop_cart.models import Cart, CartItem
from order_service.models import Order, OrderItem
from products.models import Product
from products.serializers import CartSerializer, OrderSerializer
from accounts.models import ActivityLog
import json

# ============ Shopping Cart Endpoints ============

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_cart(request):
    """Get user's shopping cart"""
    try:
        cart, created = Cart.objects.get_or_create(user=request.user)
        serializer = CartSerializer(cart)
        
        return Response({
            'status': 'success',
            'cart': serializer.data
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_to_cart(request):
    """Add product to cart"""
    try:
        product_id = request.data.get('product_id')
        quantity = request.data.get('quantity', 1)
        
        if not product_id:
            return Response(
                {'error': 'product_id required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        product = get_object_or_404(Product, id=product_id)
        cart, _ = Cart.objects.get_or_create(user=request.user)
        
        cart_item, created = CartItem.objects.get_or_create(
            cart=cart,
            product=product,
            defaults={'quantity': quantity}
        )
        
        if not created:
            cart_item.quantity += quantity
            cart_item.save()
        
        # Log activity
        ActivityLog.objects.create(
            user=request.user,
            action='add_to_cart',
            product=product,
            details={'quantity': quantity}
        )
        
        serializer = CartSerializer(cart)
        
        return Response({
            'status': 'success',
            'message': 'Product added to cart',
            'cart': serializer.data
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def update_cart_item(request, item_id):
    """Update cart item quantity"""
    try:
        quantity = request.data.get('quantity')
        
        if quantity is None:
            return Response(
                {'error': 'quantity required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        cart_item = get_object_or_404(CartItem, id=item_id, cart__user=request.user)
        
        if quantity <= 0:
            cart_item.delete()
            return Response({'status': 'success', 'message': 'Item removed from cart'})
        
        cart_item.quantity = quantity
        cart_item.save()
        
        cart = cart_item.cart
        serializer = CartSerializer(cart)
        
        return Response({
            'status': 'success',
            'cart': serializer.data
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def remove_from_cart(request, item_id):
    """Remove item from cart"""
    try:
        cart_item = get_object_or_404(CartItem, id=item_id, cart__user=request.user)
        cart = cart_item.cart
        cart_item.delete()
        
        serializer = CartSerializer(cart)
        
        return Response({
            'status': 'success',
            'message': 'Item removed from cart',
            'cart': serializer.data
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def clear_cart(request):
    """Clear entire cart"""
    try:
        cart = get_object_or_404(Cart, user=request.user)
        cart.items.all().delete()
        
        serializer = CartSerializer(cart)
        
        return Response({
            'status': 'success',
            'message': 'Cart cleared',
            'cart': serializer.data
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


# ============ Order Endpoints ============

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_order(request):
    """Create order from cart"""
    try:
        cart = get_object_or_404(Cart, user=request.user)
        
        if not cart.items.exists():
            return Response(
                {'error': 'Cart is empty'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get shipping details
        shipping_data = request.data.get('shipping', {})
        
        # Create order
        order = Order.objects.create(
            user=request.user,
            total_price=cart.get_total(),
            shipping_address=shipping_data.get('address', ''),
            city=shipping_data.get('city', ''),
            state=shipping_data.get('state', ''),
            zipcode=shipping_data.get('zipcode', ''),
            country=shipping_data.get('country', ''),
        )
        
        # Copy cart items to order
        for cart_item in cart.items.all():
            OrderItem.objects.create(
                order=order,
                product=cart_item.product,
                quantity=cart_item.quantity,
                price_at_purchase=cart_item.product.current_price
            )
            
            # Log purchase activity
            ActivityLog.objects.create(
                user=request.user,
                action='purchase',
                product=cart_item.product,
                details={'quantity': cart_item.quantity}
            )
        
        # Clear cart
        cart.items.all().delete()
        
        serializer = OrderSerializer(order)
        
        return Response({
            'status': 'success',
            'message': 'Order created successfully',
            'order': serializer.data
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def order_list(request):
    """Get user's orders"""
    try:
        orders = Order.objects.filter(user=request.user)
        serializer = OrderSerializer(orders, many=True)
        
        return Response({
            'status': 'success',
            'total_orders': orders.count(),
            'orders': serializer.data
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def order_detail(request, order_id):
    """Get single order details"""
    try:
        order = get_object_or_404(Order, id=order_id, user=request.user)
        serializer = OrderSerializer(order)
        
        return Response({
            'status': 'success',
            'order': serializer.data
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def update_order_status(request, order_id):
    """Update order status (admin only)"""
    try:
        if not request.user.is_staff:
            return Response(
                {'error': 'Only admin can update order status'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        order = get_object_or_404(Order, id=order_id)
        status_value = request.data.get('status')
        
        if status_value not in ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled']:
            return Response(
                {'error': 'Invalid status'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        order.status = status_value
        order.save()
        
        serializer = OrderSerializer(order)
        
        return Response({
            'status': 'success',
            'message': f'Order status updated to {status_value}',
            'order': serializer.data
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )
