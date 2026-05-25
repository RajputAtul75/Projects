import 'dart:developer' as developer;

import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  try {
    final response = await dio.get('https://geocoding-api.open-meteo.com/v1/search?name=chennai&count=1&language=en&format=json');
    developer.log('${response.data}', name: 'test_geocoding');
  } catch (e) {
    developer.log('error: $e', name: 'test_geocoding');
  }
}
