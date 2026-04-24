import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/heat_data.dart';
import '../models/heat_zone.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'location_provider.dart';

/// Provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

/// Provider for StorageService (singleton, already initialized in main)
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(); // returns the singleton instance
});

/// Current heat data for user's location
final heatDataProvider = FutureProvider<HeatData>((ref) async {
  final location = await ref.watch(activeCityLocationProvider.future);
  final apiService = ref.read(apiServiceProvider);
  final storageService = ref.read(storageServiceProvider);

  try {
    final data = await apiService.fetchHeatRisk(
      lat: location.latitude,
      lng: location.longitude,
    );
    // Cache for offline
    await storageService.cacheHeatData(data);
    return data;
  } catch (e) {
    // Try cache
    final cached = storageService.getCachedHeatData();
    if (cached != null) return cached;
    rethrow;
  }
});

/// Heat zones near user
final heatZonesProvider = FutureProvider<List<HeatZone>>((ref) async {
  final location = await ref.watch(activeCityLocationProvider.future);
  final apiService = ref.read(apiServiceProvider);
  return apiService.fetchHeatZones(
    lat: location.latitude,
    lng: location.longitude,
  );
});

/// 7-day heat history
final heatHistoryProvider = FutureProvider<List<HeatData>>((ref) async {
  final location = await ref.watch(activeCityLocationProvider.future);
  final apiService = ref.read(apiServiceProvider);
  final storageService = ref.read(storageServiceProvider);

  try {
    final data = await apiService.fetchHeatHistory(
      lat: location.latitude,
      lng: location.longitude,
    );
    await storageService.cacheHeatHistory(data);
    return data;
  } catch (e) {
    final cached = storageService.getCachedHeatHistory();
    if (cached != null) return cached;
    rethrow;
  }
});

/// AI heat prediction (next 24 hours)
final heatPredictionProvider = FutureProvider<List<HeatData>>((ref) async {
  final location = await ref.watch(activeCityLocationProvider.future);
  final apiService = ref.read(apiServiceProvider);
  return apiService.fetchHeatPrediction(
    lat: location.latitude,
    lng: location.longitude,
  );
});
