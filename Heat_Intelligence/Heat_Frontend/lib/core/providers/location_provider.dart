import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/city_location.dart';
import '../services/location_service.dart';

/// Provider for LocationService singleton
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider for current user position
final currentPositionProvider = FutureProvider<Position>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  return await locationService.getCurrentPosition();
});

/// Selected city by user search. Null means use GPS current location.
final selectedCityProvider = StateProvider<CityLocation?>((ref) => null);

/// Active location used by map and heat providers.
final activeCityLocationProvider = FutureProvider<CityLocation>((ref) async {
  final selected = ref.watch(selectedCityProvider);
  if (selected != null) {
    return selected;
  }

  final position = await ref.watch(currentPositionProvider.future);
  return CityLocation(
    name: 'Current Location',
    latitude: position.latitude,
    longitude: position.longitude,
  );
});

/// Provider for position stream (background updates)
final positionStreamProvider = StreamProvider<Position>((ref) {
  final locationService = ref.read(locationServiceProvider);
  return locationService.getPositionStream();
});
