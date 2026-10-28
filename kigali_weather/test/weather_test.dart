import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kigali_weather/features/weather/domain/weather.dart';
import 'package:kigali_weather/features/weather/data/weather_api.dart';

Map<String, dynamic> forecastJson({num temperature = 25}) => {
  'current': {
    'time': '2026-10-27T12:30',
    'temperature_2m': temperature,
    'relative_humidity_2m': 52,
    'wind_speed_10m': 11,
    'weather_code': 3,
    'apparent_temperature': 26,
    'is_day': 1,
  },
};
void main() {
  test('parses whole and fractional numbers and round trips the cache', () {
    for (final n in [25, 25.8]) {
      final weather = Weather.fromJson(forecastJson(temperature: n));
      expect(weather.temperature, n.toDouble());
      expect(Weather.fromJson(weather.toJson()).time, '2026-10-27T12:30');
    }
  });
  test('rejects missing current readings instead of inventing zero', () {
    expect(() => Weather.fromJson({'current': {}}), throwsFormatException);
  });
  test('maps WMO snow and unknown codes accurately', () {
    expect(describe(71), 'Snow');
    expect(describe(-1), 'Unknown conditions');
    expect(describe(999), 'Unknown conditions');
  });
  test('requests exact city and explicit Kigali timezone', () async {
    final api = WeatherApi(
      MockClient((request) async {
        expect(request.url.queryParameters['latitude'], '-2.5967');
        expect(request.url.queryParameters['timezone'], 'Africa/Kigali');
        return http.Response(jsonEncode(forecastJson()), 200);
      }),
    );
    expect((await api.fetch(cities[1])).temperature, 25);
  });
  test('server errors and malformed JSON become failures', () async {
    for (final response in [
      http.Response('busy', 503),
      http.Response('{}', 200),
    ]) {
      final api = WeatherApi(MockClient((_) async => response));
      await expectLater(api.fetch(cities.first), throwsA(isA<Exception>()));
    }
  });
}
