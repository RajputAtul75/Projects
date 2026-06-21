import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// API endpoint constants
class ApiConstants {
  ApiConstants._();

  /// Base URL — change this to your deployed backend
  static String get baseUrl {
    return 'https://heat-backend-emvs.onrender.com';
  }

  /// Open-Meteo weather endpoint base (free and keyless)
  static const String weatherBaseUrl = 'https://api.open-meteo.com';

  /// Endpoints
  static const String heatRisk = '/api/heat-risk';
  static const String heatZones = '/api/heat-zones';
  static const String heatHistory = '/api/heat-history';
  static const String heatPrediction = '/api/heat-prediction';
  static const String alerts = '/api/alerts';

  /// Open-Meteo endpoint
  static const String weatherCurrent = '/v1/forecast';

  /// Timeouts (ms)
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  /// Headers
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}
