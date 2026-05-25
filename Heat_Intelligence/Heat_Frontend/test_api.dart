import 'dart:developer' as developer;

import 'package:heat_intelligence/core/services/api_service.dart';

void main() async {
  final api = ApiService();
  try {
    final result = await api.fetchHeatRisk(lat: 22.3072, lng: 73.1812);
    developer.log(
      'Temp: ${result.temperature}, Score: ${result.riskScore}, Location: ${result.locationName}',
      name: 'test_api',
    );
  } catch (e) {
    developer.log('Error: $e', name: 'test_api');
  }
}
