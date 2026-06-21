import 'package:dio/dio.dart';

void main() async {
  try {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://heat-backend-emvs.onrender.com',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-App-Version': '1.0.0',
      }
    ));
    final response = await dio.get(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': 28.6139,
        'longitude': 77.2090,
        'current': 'temperature_2m,relative_humidity_2m,wind_speed_10m',
        'timezone': 'auto',
      },
    );
    print(response.data);
  } catch (e) {
    print('Error: $e');
  }
}
