import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/city_location.dart';

/// Service for GPS location access
class LocationService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );

  /// Check and request location permissions, then return current position
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
          'Location permission permanently denied. Please enable in settings.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      ),
    );
  }

  /// Stream location updates for background monitoring
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 200, // Update every 200m
      ),
    );
  }

  /// Search any city by name and return coordinates for map/heat queries.
  Future<CityLocation> searchCity(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      throw LocationException('Please enter a city name.');
    }

    // First try native/platform geocoding.
    try {
      final results = await locationFromAddress(trimmed);
      if (results.isNotEmpty) {
        final first = results.first;
        return CityLocation(
          name: trimmed,
          latitude: first.latitude,
          longitude: first.longitude,
        );
      }
    } catch (e) {
      developer.log('locationFromAddress failed: $e', name: 'LocationService');
    }

    // Fallback for web/unsupported platforms: Open-Meteo geocoding API.
    try {
      final response = await _dio.get(
        'https://geocoding-api.open-meteo.com/v1/search',
        queryParameters: {
          'name': trimmed,
          'count': 1,
          'language': 'en',
          'format': 'json',
        },
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const FormatException('Unexpected geocoding response format.');
      }

      final results = body['results'];
      if (results is! List || results.isEmpty) {
        throw LocationException('No matching city found.');
      }

      final first = results.first;
      if (first is! Map<String, dynamic>) {
        throw const FormatException('Unexpected geocoding result format.');
      }

      final lat = (first['latitude'] as num?)?.toDouble();
      final lng = (first['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) {
        throw const FormatException('Missing coordinates for searched city.');
      }

      final cityName = first['name'] as String?;
      final country = first['country'] as String?;
      final label = cityName == null
          ? trimmed
          : country == null
              ? cityName
              : '$cityName, $country';

      return CityLocation(
        name: label,
        latitude: lat,
        longitude: lng,
      );
    } on LocationException {
      rethrow;
    } catch (e) {
      developer.log('Open-Meteo geocoding failed: $e', name: 'LocationService');
      throw LocationException('Could not find that city. Try another name.');
    }
  }

  /// Calculate distance between two GPS points (meters)
  double distanceBetween(
      double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}
