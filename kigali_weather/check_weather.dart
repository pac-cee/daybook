// Console exercises intentionally print their results.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kigali_weather/features/weather/data/weather_api.dart';
import 'package:kigali_weather/features/weather/domain/weather.dart';

Future<void> main() async {
  final client = http.Client();
  try {
    final api = WeatherApi(client);
    final readings = await Future.wait(cities.map(api.fetch));
    for (var i = 0; i < cities.length; i++) {
      final w = readings[i];
      print(
        '${cities[i].name}: ${w.temperature}°C, humidity ${w.humidity}%, wind ${w.wind} km/h, ${describe(w.code)}. Observed ${w.time} Africa/Kigali.',
      );
    }
    final difference = readings[1].temperature - readings[0].temperature;
    print(
      'Huye is ${difference.abs().toStringAsFixed(1)}°C ${difference < 0
          ? 'colder'
          : difference > 0
          ? 'warmer'
          : 'different (equal temperature)'} than Kigali.',
    );
  } catch (error) {
    stderr.writeln('Could not check live weather: $error');
    exitCode = 1;
  } finally {
    client.close();
  }
}
