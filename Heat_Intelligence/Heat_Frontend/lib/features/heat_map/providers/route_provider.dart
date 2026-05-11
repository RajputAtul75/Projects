import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_segment.dart';
import '../services/heat_route_service.dart';

final originProvider = StateProvider<LatLng?>((ref) => null);
final destinationProvider = StateProvider<LatLng?>((ref) => null);

final routeSegmentProvider = FutureProvider<List<RouteSegment>>((ref) async {
  final origin = ref.watch(originProvider);
  final destination = ref.watch(destinationProvider);
  if (origin == null || destination == null) return [];

  final heatRouteService = ref.watch(heatRouteServiceProvider);
  return heatRouteService.planHeatSafeRoute(origin, destination);
});
