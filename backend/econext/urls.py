"""
URL configuration for econext project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from products.views import welcome
from shop_cart import api_views as cart_views

urlpatterns = [
    path('', welcome, name='welcome'),
    path('admin/', admin.site.urls),
    
    # API endpoints
    path('api/', include('accounts.urls')),
    path('api/products/', include('products.urls')),
    
    # Cart endpoints
    path('api/cart/', cart_views.get_cart, name='get_cart'),
    path('api/cart/add/', cart_views.add_to_cart, name='add_to_cart'),
    path('api/cart/item/<int:item_id>/', cart_views.update_cart_item, name='update_cart_item'),
    path('api/cart/item/<int:item_id>/delete/', cart_views.remove_from_cart, name='remove_from_cart'),
    path('api/cart/clear/', cart_views.clear_cart, name='clear_cart'),
    
    # Order endpoints
    path('api/orders/create/', cart_views.create_order, name='create_order'),
    path('api/orders/', cart_views.order_list, name='order_list'),
    path('api/orders/<int:order_id>/', cart_views.order_detail, name='order_detail'),
    path('api/orders/<int:order_id>/status/', cart_views.update_order_status, name='update_order_status'),
]
