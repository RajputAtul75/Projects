import 'package:dio/dio.dart';

void main() async {
  try {
    final dio = Dio();
    final response = await dio.get(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': 28.6,
        'longitude': 77.2,
        'current': 'temperature_2m,relative_humidity_2m,wind_speed_10m',
        'timezone': 'auto',
      },
    );
    final data = response.data as Map<String, dynamic>;
    final current = data['current'] as Map<String, dynamic>?;

    final temp = (current?['temperature_2m'] as num?)?.toDouble();
    final humidity = (current?['relative_humidity_2m'] as num?)?.toDouble();

    print('Temp: $temp, Humidity: $humidity');
    
  } catch (e, stack) {
    print('ERROR: $e');
    print(stack);
  }
}
