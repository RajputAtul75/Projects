from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.views.decorators.http import require_http_methods
from .serializers import SignUpSerializer, LoginSerializer, UserSerializer, UserProfileSerializer
from .models import UserProfile

@api_view(['POST'])
@permission_classes([AllowAny])
def signup_view(request):
    """User registration endpoint"""
    serializer = SignUpSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response({
            'status': 'success',
            'message': 'User registered successfully',
            'user': UserSerializer(user).data,
            'tokens': {
                'access': str(refresh.access_token),
                'refresh': str(refresh)
            }
        }, status=status.HTTP_201_CREATED)
    return Response({
        'status': 'error',
        'message': 'Signup failed',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def login_view(request):
    """User login endpoint"""
    serializer = LoginSerializer(data=request.data)
    if serializer.is_valid():
        username = serializer.validated_data['username']
        password = serializer.validated_data['password']
        
        user = authenticate(username=username, password=password)
        if user is not None:
            refresh = RefreshToken.for_user(user)
            try:
                profile = UserProfile.objects.get(user=user)
            except UserProfile.DoesNotExist:
                profile = UserProfile.objects.create(user=user)
            return Response({
                'status': 'success',
                'message': 'Login successful',
                'user': UserSerializer(user).data,
                'profile': UserProfileSerializer(profile).data,
                'tokens': {
                    'access': str(refresh.access_token),
                    'refresh': str(refresh)
                }
            }, status=status.HTTP_200_OK)
        else:
            return Response({
                'status': 'error',
                'message': 'Invalid username or password'
            }, status=status.HTTP_401_UNAUTHORIZED)
    return Response({
        'status': 'error',
        'message': 'Invalid credentials',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def current_user_view(request):
    """Get current authenticated user"""
    try:
        profile = UserProfile.objects.get(user=request.user)
        return Response({
            'status': 'success',
            'user': UserSerializer(request.user).data,
            'profile': UserProfileSerializer(profile).data
        }, status=status.HTTP_200_OK)
    except UserProfile.DoesNotExist:
        return Response({
            'status': 'error',
            'message': 'User profile not found'
        }, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    """User logout endpoint"""
    return Response({
        'status': 'success',
        'message': 'Logout successful'
    }, status=status.HTTP_200_OK)

@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_profile_view(request):
    """Update user profile"""
    try:
        profile = UserProfile.objects.get(user=request.user)
        
        # Update user fields
        user = request.user
        if 'first_name' in request.data:
            user.first_name = request.data['first_name']
        if 'last_name' in request.data:
            user.last_name = request.data['last_name']
        if 'email' in request.data:
            user.email = request.data['email']
        user.save()
        
        # Update profile fields
        if 'phone' in request.data:
            profile.phone = request.data['phone']
        if 'address' in request.data:
            profile.address = request.data['address']
        if 'city' in request.data:
            profile.city = request.data['city']
        if 'country' in request.data:
            profile.country = request.data['country']
        if 'postal_code' in request.data:
            profile.postal_code = request.data['postal_code']
        profile.save()
        
        return Response({
            'status': 'success',
            'message': 'Profile updated successfully',
            'user': UserSerializer(user).data,
            'profile': UserProfileSerializer(profile).data
        }, status=status.HTTP_200_OK)
    except UserProfile.DoesNotExist:
        return Response({
            'status': 'error',
            'message': 'User profile not found'
        }, status=status.HTTP_404_NOT_FOUND)
