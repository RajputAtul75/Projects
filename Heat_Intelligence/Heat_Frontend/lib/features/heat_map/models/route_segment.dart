import 'package:latlong2/latlong.dart';

class RouteSegment {
  final List<LatLng> points;
  final double heatScore; // 0 to 100
  final double distance; // in meters

  const RouteSegment({
    required this.points,
    required this.heatScore,
    required this.distance,
  });
}
