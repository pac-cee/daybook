import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/weather.dart';

class WeatherApi {
  WeatherApi(this.client, {this.timeout = const Duration(seconds: 12)});
  final http.Client client;
  final Duration timeout;
  Future<Weather> fetch(City city) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${city.latitude}',
      'longitude': '${city.longitude}',
      'current': 'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code,apparent_temperature,is_day',
      'hourly': 'temperature_2m,weather_code,precipitation_probability',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'timezone': 'Africa/Kigali',
      'forecast_days': '7',
      'temperature_unit': 'celsius',
      'wind_speed_unit': 'kmh',
    });
    final response = await client.get(uri).timeout(timeout);
    if (response.statusCode != 200) {
      throw WeatherApiException(response.statusCode);
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid weather response');
    }
    return Weather.fromJson(data);
  }
}

class WeatherApiException implements Exception {
  const WeatherApiException(this.statusCode);
  final int statusCode;
}
