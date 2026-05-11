import 'package:equatable/equatable.dart';

enum AlertSeverity { high, moderate, low }

/// Represents an alert notification
class AlertModel extends Equatable {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final double riskScore;
  final String locationName;
  final DateTime timestamp;
  final bool isRead;

  const AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.riskScore,
    required this.locationName,
    required this.timestamp,
    this.isRead = false,
  });

  AlertModel copyWith({bool? isRead}) => AlertModel(
        id: id,
        title: title,
        message: message,
        severity: severity,
        riskScore: riskScore,
        locationName: locationName,
        timestamp: timestamp,
        isRead: isRead ?? this.isRead,
      );

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.low,
      ),
      riskScore: (json['risk_score'] as num).toDouble(),
      locationName: json['location_name'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'severity': severity.name,
        'risk_score': riskScore,
        'location_name': locationName,
        'timestamp': timestamp.toIso8601String(),
        'is_read': isRead,
      };

  static List<AlertModel> dummyAlerts() => [
        AlertModel(
          id: '1',
          title: '🔴 Extreme Heat Warning',
          message:
              'Temperature in Industrial Zone A has reached 42.3°C. Risk score: 0.85. Avoid outdoor exposure.',
          severity: AlertSeverity.high,
          riskScore: 0.85,
          locationName: 'Industrial Zone A',
          timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        ),
        AlertModel(
          id: '2',
          title: '🟡 Moderate Heat Advisory',
          message:
              'Market District is experiencing elevated temperatures (37.8°C). Stay hydrated.',
          severity: AlertSeverity.moderate,
          riskScore: 0.62,
          locationName: 'Market District',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        AlertModel(
          id: '3',
          title: '🔴 Heat Stroke Risk',
          message:
              'Highway Corridor has a risk score of 0.78. Limit outdoor activities.',
          severity: AlertSeverity.high,
          riskScore: 0.78,
          locationName: 'Highway Corridor',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        AlertModel(
          id: '4',
          title: '🟢 Zone Cleared',
          message:
              'Park Area temperatures have dropped to safe levels (33.1°C).',
          severity: AlertSeverity.low,
          riskScore: 0.30,
          locationName: 'Park Area',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ];

  @override
  List<Object?> get props => [id, title, severity, timestamp];
}
