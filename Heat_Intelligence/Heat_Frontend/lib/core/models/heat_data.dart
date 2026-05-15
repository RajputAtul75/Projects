import 'package:equatable/equatable.dart';

/// Represents heat risk data returned from the API
class HeatData extends Equatable {
  final double latitude;
  final double longitude;
  final double temperature; // °C
  final double heatIndex;
  final double humidity;
  final double riskScore; // 0.0 – 1.0
  final String locationName;
  final DateTime timestamp;
  final double? windSpeed;
  final double? uvIndex;

  const HeatData({
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.heatIndex,
    required this.humidity,
    required this.riskScore,
    required this.locationName,
    required this.timestamp,
    this.windSpeed,
    this.uvIndex,
  });

  HeatData copyWith({
    double? latitude,
    double? longitude,
    double? temperature,
    double? heatIndex,
    double? humidity,
    double? riskScore,
    String? locationName,
    DateTime? timestamp,
    double? windSpeed,
    double? uvIndex,
  }) {
    return HeatData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      temperature: temperature ?? this.temperature,
      heatIndex: heatIndex ?? this.heatIndex,
      humidity: humidity ?? this.humidity,
      riskScore: riskScore ?? this.riskScore,
      locationName: locationName ?? this.locationName,
      timestamp: timestamp ?? this.timestamp,
      windSpeed: windSpeed ?? this.windSpeed,
      uvIndex: uvIndex ?? this.uvIndex,
    );
  }

  /// Risk level label
  String get riskLabel {
    if (riskScore >= 0.75) return 'High Risk';
    if (riskScore >= 0.40) return 'Moderate';
    return 'Safe';
  }

  /// Risk emoji
  String get riskEmoji {
    if (riskScore >= 0.75) return '🔴';
    if (riskScore >= 0.40) return '🟡';
    return '🟢';
  }

  /// Parse from JSON
  factory HeatData.fromJson(Map<String, dynamic> json) {
    return HeatData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      heatIndex: (json['heat_index'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      riskScore: (json['risk_score'] as num).toDouble(),
      locationName: json['location_name'] as String? ?? 'Unknown',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      windSpeed: (json['wind_speed'] as num?)?.toDouble(),
      uvIndex: (json['uv_index'] as num?)?.toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'temperature': temperature,
        'heat_index': heatIndex,
        'humidity': humidity,
        'risk_score': riskScore,
        'location_name': locationName,
        'timestamp': timestamp.toIso8601String(),
        'wind_speed': windSpeed,
        'uv_index': uvIndex,
      };

  /// Dummy data for development / offline
  static HeatData dummy({double? lat, double? lng}) => HeatData(
        latitude: lat ?? 28.6139,
        longitude: lng ?? 77.2090,
        temperature: 38.5,
        heatIndex: 42.1,
        humidity: 65,
        riskScore: 0.82,
        locationName: 'New Delhi',
        timestamp: DateTime.now(),
        windSpeed: 8.5,
        uvIndex: 9.2,
      );

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        temperature,
        heatIndex,
        humidity,
        riskScore,
        locationName,
        timestamp,
      ];
}
