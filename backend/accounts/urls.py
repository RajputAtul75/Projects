from django.urls import path
from . import auth_views

urlpatterns = [
    path('auth/signup/', auth_views.signup_view, name='signup'),
    path('auth/login/', auth_views.login_view, name='login'),
    path('auth/logout/', auth_views.logout_view, name='logout'),
    path('auth/current-user/', auth_views.current_user_view, name='current-user'),
    path('auth/profile/update/', auth_views.update_profile_view, name='update-profile'),
]
