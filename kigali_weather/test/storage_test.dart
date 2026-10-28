import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kigali_weather/core/app_database.dart';
import 'package:kigali_weather/features/tasks/domain/task.dart';
import 'package:kigali_weather/features/tasks/data/task_repository.dart';
import 'package:kigali_weather/features/weather/data/weather_repository.dart';
import 'package:kigali_weather/features/weather/domain/weather.dart';

import 'weather_test.dart' show forecastJson;

void main() {
  late Directory directory;
  late AppDatabase database;
  setUp(() async {
    sqfliteFfiInit();
    directory = await Directory.systemTemp.createTemp('session5-test-');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${directory.path}/app.db',
    );
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });
  test('three changes survive reopen; deleted samples do not return; undo persists', () async {
    var tasks = TaskRepository(database);
    final samples = await tasks.load();
    expect(samples, isNotEmpty);
    final added = Task(
      id: 'new',
      title: 'Read chapter',
      notes: 'Pages 1–20',
      priority: 2,
      done: false,
    );
    await tasks.save(added);
    await tasks.save(added.copyWith(title: 'Read chapter 2', done: true));
    await tasks.delete(samples.first);
    await database.close();
    tasks = TaskRepository(database);
    final reopened = await tasks.load();
    expect(reopened.firstWhere((t) => t.id == 'new').done, true);
    expect(reopened.any((t) => t.id == samples.first.id), false);
    await tasks.undoDelete();
    await database.close();
    expect((await tasks.load()).any((t) => t.id == samples.first.id), true);
    for (final task in await tasks.load()) {
      await tasks.delete(task);
    }
    await database.close();
    expect(await tasks.load(), isEmpty);
  });
  test('weather snapshots stay separate by city across reopening', () async {
    final cache = WeatherCache(database);
    await cache.save(
      cities[0],
      Weather.fromJson(forecastJson(temperature: 25)),
    );
    await cache.save(
      cities[1],
      Weather.fromJson(forecastJson(temperature: 19)),
    );
    await database.close();
    expect((await cache.read(cities[0]))!.temperature, 25);
    expect((await cache.read(cities[1]))!.temperature, 19);
    expect(await cache.read(cities[2]), isNull);
  });
  test('task validation rejects blank titles', () {
    expect(
      () => Task(id: 'a', title: '  ', priority: 0, done: false),
      throwsArgumentError,
    );
  });
}
