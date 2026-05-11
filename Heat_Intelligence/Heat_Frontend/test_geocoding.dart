import 'package:dio/dio.dart';
void main() async {
  final dio = Dio();
  try {
    final response = await dio.get('https://geocoding-api.open-meteo.com/v1/search?name=chennai&count=1&language=en&format=json');
    print(response.data);
  } catch (e) {
    print('error: $e');
  }
}
