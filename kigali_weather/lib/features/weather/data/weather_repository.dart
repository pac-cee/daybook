import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/app_database.dart';
import '../domain/weather.dart';

class WeatherCache {
  WeatherCache(this.database);
  final AppDatabase database;
  Future<void> save(City city, Weather weather) async {
    final db = await database.connection;
    await db.insert('weather_cache', {
      'city': city.name,
      'payload': jsonEncode(weather.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Weather?> read(City city) async {
    final db = await database.connection;
    final rows = await db.query(
      'weather_cache',
      where: 'city = ?',
      whereArgs: [city.name],
    );
    if (rows.isEmpty) return null;
    try {
      return Weather.fromJson(
        jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>,
      );
    } on FormatException {
      return null;
    }
  }
}
