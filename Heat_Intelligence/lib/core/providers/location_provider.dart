import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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

/// Provider for position stream (background updates)
final positionStreamProvider = StreamProvider<Position>((ref) {
  final locationService = ref.read(locationServiceProvider);
  return locationService.getPositionStream();
});
