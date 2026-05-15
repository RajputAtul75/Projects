import 'lib/core/services/api_service.dart';

void main() async {
  final api = ApiService();
  try {
    final result = await api.fetchHeatRisk(lat: 22.3072, lng: 73.1812);
    print('Temp: ${result.temperature}, Score: ${result.riskScore}, Location: ${result.locationName}');
  } catch (e) {
    print('Error: $e');
  }
}
