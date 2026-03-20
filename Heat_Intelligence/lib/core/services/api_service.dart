import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/heat_data.dart';
import '../models/heat_zone.dart';

/// HTTP API service for communicating with the HDI backend
class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      headers: ApiConstants.defaultHeaders,
    ));

    // Logging interceptor for debug builds
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => developer.log('$obj', name: 'API'),
    ));
  }

  /// GET /api/heat-risk?lat={lat}&lng={lng}
  Future<HeatData> fetchHeatRisk({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.heatRisk,
        queryParameters: {'lat': lat, 'lng': lng},
      );
      return HeatData.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (_) {
      // Return dummy data for offline / development
      return HeatData.dummy(lat: lat, lng: lng);
    }
  }

  /// Fetch heat zones near the user
  Future<List<HeatZone>> fetchHeatZones({
    required double lat,
    required double lng,
    double radiusKm = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.heatZones,
        queryParameters: {'lat': lat, 'lng': lng, 'radius': radiusKm},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => HeatZone.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (_) {
      return HeatZone.dummyZones(lat, lng);
    }
  }

  /// Fetch 7-day heat history
  Future<List<HeatData>> fetchHeatHistory({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.heatHistory,
        queryParameters: {'lat': lat, 'lng': lng},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => HeatData.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (_) {
      // Generate dummy 7-day data
      return _generateDummyHistory(lat, lng);
    }
  }

  /// Fetch AI-based 24-hour prediction
  Future<List<HeatData>> fetchHeatPrediction({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.heatPrediction,
        queryParameters: {'lat': lat, 'lng': lng},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => HeatData.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (_) {
      return _generateDummyPrediction(lat, lng);
    }
  }

  List<HeatData> _generateDummyHistory(double lat, double lng) {
    final now = DateTime.now();
    final temps = [34.2, 36.5, 38.1, 39.8, 37.4, 35.9, 38.5];
    final risks = [0.35, 0.52, 0.68, 0.81, 0.55, 0.42, 0.82];
    return List.generate(7, (i) {
      return HeatData(
        latitude: lat,
        longitude: lng,
        temperature: temps[i],
        heatIndex: temps[i] + 3.5,
        humidity: (55 + i * 2).toDouble(),
        riskScore: risks[i],
        locationName: 'Current Location',
        timestamp: now.subtract(Duration(days: 6 - i)),
        windSpeed: 5.0 + i,
        uvIndex: 6.0 + i * 0.5,
      );
    });
  }

  List<HeatData> _generateDummyPrediction(double lat, double lng) {
    final now = DateTime.now();
    final temps = [37.0, 38.5, 40.2, 41.1, 40.5, 39.2, 37.8, 36.5];
    final risks = [0.55, 0.68, 0.82, 0.88, 0.80, 0.72, 0.58, 0.48];
    return List.generate(8, (i) {
      return HeatData(
        latitude: lat,
        longitude: lng,
        temperature: temps[i],
        heatIndex: temps[i] + 4.0,
        humidity: (60 + i).toDouble(),
        riskScore: risks[i],
        locationName: 'Current Location',
        timestamp: now.add(Duration(hours: (i + 1) * 3)),
      );
    });
  }
}
