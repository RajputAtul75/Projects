import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/route_segment.dart';

final heatRouteServiceProvider = Provider<HeatRouteService>((ref) {
  return HeatRouteService(Dio());
});

class HeatRouteService {
  final Dio _dio;

  HeatRouteService(this._dio);

  Future<List<RouteSegment>> planHeatSafeRoute(LatLng origin, LatLng dest) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'route_${origin.latitude}_${origin.longitude}_${dest.latitude}_${dest.longitude}';
    final cached = prefs.getString(cacheKey);
    final cacheTime = prefs.getInt('${cacheKey}_time');

    if (cached != null && cacheTime != null && DateTime.now().millisecondsSinceEpoch - cacheTime < 30 * 60 * 1000) {
      final decodedList = jsonDecode(cached) as List;
      return decodedList.map((e) => _segmentFromJson(e)).toList();
    }

    try {
      // 1. Fetch OSRM Route
      final response = await _dio.get(
        'http://router.project-osrm.org/route/v1/foot/${origin.longitude},${origin.latitude};${dest.longitude},${dest.latitude}?geometries=geojson',
      );

      final routes = response.data['routes'] as List;
      if (routes.isEmpty) return [];

      final coords = routes[0]['geometry']['coordinates'] as List;
      final distance = routes[0]['distance'] as double;
      
      final points = coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();

      if (points.isEmpty) return [];

      // 2. Break points into chunks/segments and sample 8 points
      final int numChunks = 8;
      final int chunkSize = (points.length / numChunks).ceil();
      final List<RouteSegment> segments = [];

      for (int i = 0; i < numChunks; i++) {
        int start = i * chunkSize;
        int end = (i + 1) * chunkSize;
        if (start >= points.length) break;
        if (end > points.length) end = points.length;
        
        final chunk = points.sublist(start, end);
        if (chunk.isEmpty) continue;

        // Sample middle point of chunk for weather
        final samplePoint = chunk[chunk.length ~/ 2];
        final heatScore = await _fetchHeatScore(samplePoint);

        segments.add(RouteSegment(
          points: chunk,
          heatScore: heatScore,
          distance: distance / numChunks, // approximate
        ));
      }

      final encoded = jsonEncode(segments.map((s) => _segmentToJson(s)).toList());
      await prefs.setString(cacheKey, encoded);
      await prefs.setInt('${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);

      return segments;
    } catch (e) {
      // Return empty or throw
      return [];
    }
  }

  Future<double> _fetchHeatScore(LatLng p) async {
    try {
      final res = await _dio.get(
        'https://api.open-meteo.com/v1/forecast?latitude=${p.latitude}&longitude=${p.longitude}&current=temperature_2m,relative_humidity_2m,uv_index',
      );
      final current = res.data['current'];
      final double tempC = (current['temperature_2m'] as num).toDouble();
      final double rh = (current['relative_humidity_2m'] as num).toDouble();
      final double uv = (current['uv_index'] as num).toDouble();

      // Convert to F
      final double tempF = (tempC * 9 / 5) + 32;

      // Rothfusz formula calculate heat index
      double heatIndex = -42.379 +
          2.04901523 * tempF +
          10.14333127 * rh -
          0.22475541 * tempF * rh -
          0.00683783 * tempF * tempF -
          0.05481717 * rh * rh +
          0.00122874 * tempF * tempF * rh +
          0.00085282 * tempF * rh * rh -
          0.00000199 * tempF * tempF * rh * rh;

      if (tempF < 80) {
        heatIndex = tempF;
      }

      // Map heat index (e.g. 80 - 130) to score 0 - 100
      double score = ((heatIndex - 80) / 40) * 100;
      
      // Add UV penalty
      score += (uv * 3);

      return score.clamp(0, 100).toDouble();
    } catch (_) {
      return 50.0;
    }
  }

  Map<String, dynamic> _segmentToJson(RouteSegment s) {
    return {
      'points': s.points.map((p) => [p.latitude, p.longitude]).toList(),
      'heatScore': s.heatScore,
      'distance': s.distance,
    };
  }

  RouteSegment _segmentFromJson(Map<String, dynamic> json) {
    final pointsList = json['points'] as List;
    return RouteSegment(
      points: pointsList.map((p) => LatLng(p[0] as double, p[1] as double)).toList(),
      heatScore: json['heatScore'] as double,
      distance: json['distance'] as double,
    );
  }
}
