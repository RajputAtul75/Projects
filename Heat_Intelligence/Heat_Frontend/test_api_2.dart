import 'package:heat_intelligence/core/services/api_service.dart';

void main() async {
  final api = ApiService();
  try {
    final data = await api.fetchHeatRisk(lat: 28.6139, lng: 77.2090, locationName: 'New Delhi');
    print('SUCCESS!');
    print(data.temperature);
  } catch (e, stack) {
    print('ERROR: $e');
    print(stack);
  }
}
