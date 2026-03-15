import 'package:equatable/equatable.dart';

/// Represents a heat zone on the map
class HeatZone extends Equatable {
  final String id;
  final double latitude;
  final double longitude;
  final double radius; // meters
  final double riskScore;
  final double temperature;
  final String name;
  final DateTime updatedAt;

  const HeatZone({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.riskScore,
    required this.temperature,
    required this.name,
    required this.updatedAt,
  });

  factory HeatZone.fromJson(Map<String, dynamic> json) {
    return HeatZone(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toDouble() ?? 500,
      riskScore: (json['risk_score'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      name: json['name'] as String? ?? 'Zone',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'risk_score': riskScore,
        'temperature': temperature,
        'name': name,
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Generate sample zones around a center
  static List<HeatZone> dummyZones(double lat, double lng) => [
        HeatZone(
          id: '1',
          latitude: lat + 0.008,
          longitude: lng + 0.005,
          radius: 600,
          riskScore: 0.85,
          temperature: 42.3,
          name: 'Industrial Zone A',
          updatedAt: DateTime.now(),
        ),
        HeatZone(
          id: '2',
          latitude: lat - 0.005,
          longitude: lng + 0.012,
          radius: 450,
          riskScore: 0.62,
          temperature: 37.8,
          name: 'Market District',
          updatedAt: DateTime.now(),
        ),
        HeatZone(
          id: '3',
          latitude: lat + 0.015,
          longitude: lng - 0.008,
          radius: 350,
          riskScore: 0.30,
          temperature: 33.1,
          name: 'Park Area',
          updatedAt: DateTime.now(),
        ),
        HeatZone(
          id: '4',
          latitude: lat - 0.012,
          longitude: lng - 0.006,
          radius: 500,
          riskScore: 0.78,
          temperature: 40.5,
          name: 'Highway Corridor',
          updatedAt: DateTime.now(),
        ),
        HeatZone(
          id: '5',
          latitude: lat + 0.003,
          longitude: lng + 0.018,
          radius: 400,
          riskScore: 0.45,
          temperature: 36.2,
          name: 'Residential Block C',
          updatedAt: DateTime.now(),
        ),
      ];

  @override
  List<Object?> get props => [id, latitude, longitude, riskScore];
}
