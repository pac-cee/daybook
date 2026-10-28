import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kigali_weather/core/app_database.dart';
import 'package:kigali_weather/features/weather/data/weather_repository.dart';
import 'package:kigali_weather/features/weather/domain/weather.dart';
import 'package:kigali_weather/features/weather/presentation/weather_controller.dart';

import 'weather_test.dart' show forecastJson;

void main() {
  late AppDatabase db;
  late WeatherCache cache;
  late Directory directory;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    directory = await Directory.systemTemp.createTemp('weather-controller-');
    db = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${directory.path}/test.db',
    );
    cache = WeatherCache(db);
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });
  test('offline uses only the selected city cache; retry recovers', () async {
    var online = false;
    await cache.save(cities.first, Weather.fromJson(forecastJson()));
    final state = WeatherController(cache, (city) async {
      if (!online) throw const SocketException('offline');
      return Weather.fromJson(forecastJson(temperature: 30));
    });
    await state.start();
    expect(state.offline, true);
    expect(state.weather!.temperature, 25);
    await state.select(cities[1]);
    expect(state.weather, isNull);
    expect(state.error, isNotNull);
    online = true;
    await state.load();
    expect(state.offline, false);
    expect(state.weather!.temperature, 30);
    expect((await SharedPreferences.getInstance()).getString('city'), 'Huye');
    state.dispose();
  });
  test('slow previous city response cannot overwrite latest city', () async {
    final first = Completer<Weather>();
    final state = WeatherController(
      cache,
      (city) => city == cities.first
          ? first.future
          : Future.value(Weather.fromJson(forecastJson(temperature: 18))),
    );
    final starting = state.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await state.select(cities[2]);
    first.complete(Weather.fromJson(forecastJson(temperature: 29)));
    await starting;
    expect(state.city.name, 'Musanze');
    expect(state.weather!.temperature, 18);
    state.dispose();
  });
}
