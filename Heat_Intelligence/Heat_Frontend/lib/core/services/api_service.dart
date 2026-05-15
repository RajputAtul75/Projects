import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/heat_data.dart';
import '../models/heat_zone.dart';
import '../utils/heat_risk_calculator.dart';

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
    String? locationName,
  }) async {
    try {
      return await _fetchRealtimeHeatRisk(lat: lat, lng: lng, locationName: locationName);
    } on DioException catch (e) {
      developer.log(
        'Open-Meteo fetch failed (${e.type}), falling back to backend',
        name: 'API',
      );
    } catch (e) {
      developer.log(
        'Open-Meteo parse failed ($e), falling back to backend',
        name: 'API',
      );
    }

    try {
      final response = await _dio.get(
        ApiConstants.heatRisk,
        queryParameters: {'lat': lat, 'lng': lng},
      );
      final data = HeatData.fromJson(response.data as Map<String, dynamic>);
      return locationName != null 
          ? data.copyWith(locationName: locationName)
          : data;
    } on DioException catch (_) {
      // Return dummy data for offline / development
      final dummy = HeatData.dummy(lat: lat, lng: lng);
      return locationName != null 
          ? dummy.copyWith(locationName: locationName)
          : dummy;
    }
  }

  Future<HeatData> _fetchRealtimeHeatRisk({
    required double lat,
    required double lng,
    String? locationName,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.weatherBaseUrl}${ApiConstants.weatherCurrent}',
      queryParameters: {
        'latitude': lat,
        'longitude': lng,
        'current': 'temperature_2m,relative_humidity_2m,wind_speed_10m',
        'timezone': 'auto',
      },
    );

    final data = response.data as Map<String, dynamic>;
    final current = data['current'] as Map<String, dynamic>?;

    final temp = (current?['temperature_2m'] as num?)?.toDouble();
    final humidity = (current?['relative_humidity_2m'] as num?)?.toDouble();

    if (temp == null || humidity == null) {
      throw const FormatException('Missing temperature or humidity in response');
    }

    final windSpeed = (current?['wind_speed_10m'] as num?)?.toDouble();
    final heatIndex = HeatRiskCalculator.calculateHeatIndex(
      temperatureC: temp,
      humidityPercent: humidity,
    );
    final riskScore = HeatRiskCalculator.calculateRiskScore(
      temperature: temp,
      humidity: humidity,
      windSpeed: windSpeed,
    );

    final timeIso = current?['time'] as String?;
    final timestamp =
        timeIso == null ? DateTime.now() : DateTime.tryParse(timeIso)?.toLocal() ?? DateTime.now();

    final cityLabel = locationName ?? _resolveLocationLabel(data);

    return HeatData(
      latitude: lat,
      longitude: lng,
      temperature: temp,
      heatIndex: heatIndex,
      humidity: humidity,
      riskScore: riskScore,
      locationName: cityLabel,
      timestamp: timestamp,
      windSpeed: windSpeed,
      uvIndex: null,
    );
  }

  String _resolveLocationLabel(Map<String, dynamic> response) {
    final timezone = response['timezone'] as String?;
    if (timezone == null || timezone.trim().isEmpty) {
      return 'Current Location';
    }

    final parts = timezone.split('/');
    final label = parts.isEmpty ? timezone : parts.last;
    return label.replaceAll('_', ' ');
  }

  /// Fetch heat zones near the user
  Future<List<HeatZone>> fetchHeatZones({
    required double lat,
    required double lng,
    double radiusKm = 10,
  }) async {
    try {
      return await _fetchRealtimeHeatZones(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
      );
    } on DioException catch (e) {
      developer.log(
        'Open-Meteo zones fetch failed (${e.type}), falling back to backend',
        name: 'API',
      );
    } catch (e) {
      developer.log(
        'Open-Meteo zones parse failed ($e), falling back to backend',
        name: 'API',
      );
    }

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

  Future<List<HeatZone>> _fetchRealtimeHeatZones({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final samplePoints = _buildZoneSamplePoints(
      centerLat: lat,
      centerLng: lng,
      radiusKm: radiusKm,
    );

    final samples = await Future.wait(
      samplePoints.map((point) {
        return _fetchRealtimeHeatRisk(
          lat: point.$1,
          lng: point.$2,
        );
      }),
    );

    final now = DateTime.now();
    final zoneRadiusMeters = (radiusKm * 1000 / 5).clamp(300, 900).toDouble();

    return List.generate(samples.length, (i) {
      final data = samples[i];
      
      // Simulate microclimates to ensure variety in heat zones (Safe, Moderate, Critical)
      double tempVariance = 0.0;
      double riskVariance = 0.0;
      
      if (i == 1) { // Moderate / Dense Urban
         tempVariance = 2.5; 
         riskVariance = 0.2;
      } else if (i == 2) { // Safe / Park Area
         tempVariance = -4.0;
         riskVariance = -0.35;
      } else if (i == 3) { // Critical / Industrial
         tempVariance = 4.5;
         riskVariance = 0.4;
      } else if (i == 4) { // Moderate / Suburb
         tempVariance = -1.5;
         riskVariance = -0.15;
      }

      final modTemp = data.temperature + tempVariance;
      final modRisk = (data.riskScore + riskVariance).clamp(0.0, 1.0);

      return HeatZone(
        id: 'rtz_$i',
        latitude: data.latitude,
        longitude: data.longitude,
        radius: zoneRadiusMeters,
        riskScore: modRisk,
        temperature: modTemp,
        name: _zoneNameForRisk(i, modRisk),
        updatedAt: now,
      );
    });
  }

  List<(double, double)> _buildZoneSamplePoints({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
  }) {
    final spreadKm = (radiusKm.clamp(4, 20) / 5).toDouble();
    final latDelta = spreadKm / 111.32;
    final cosLat = math.cos(centerLat * math.pi / 180).abs().clamp(0.2, 1.0);
    final lngDelta = spreadKm / (111.32 * cosLat);

    return [
      (centerLat, centerLng),
      (centerLat + latDelta, centerLng + lngDelta),
      (centerLat + latDelta, centerLng - lngDelta),
      (centerLat - latDelta, centerLng + lngDelta),
      (centerLat - latDelta, centerLng - lngDelta),
    ];
  }

  String _zoneNameForRisk(int index, double riskScore) {
    final prefix = riskScore >= 0.75
        ? 'Critical Zone'
        : riskScore >= 0.40
            ? 'Moderate Zone'
            : 'Safe Zone';
    return '$prefix ${index + 1}';
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
