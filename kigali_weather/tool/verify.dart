// Headless verification for environments where the test runner cannot bind sockets.
// Uses the real Flutter engine, real SQLite and deterministic HTTP fixtures.
import 'dart:async';

import 'generate_icons.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kigali_weather/core/app_database.dart';
import 'package:kigali_weather/core/theme.dart';
import 'package:kigali_weather/features/weather/domain/weather.dart';
import 'package:kigali_weather/features/weather/data/weather_api.dart';
import 'package:kigali_weather/features/weather/data/weather_repository.dart';
import 'package:kigali_weather/features/weather/presentation/weather_controller.dart';
import 'package:kigali_weather/features/weather/presentation/weather_screen.dart';
import 'package:kigali_weather/features/tasks/domain/task.dart';
import 'package:kigali_weather/features/tasks/data/task_repository.dart';
import 'package:kigali_weather/features/tasks/presentation/task_controller.dart';
import 'package:kigali_weather/features/tasks/presentation/task_screen.dart';
import 'package:kigali_weather/features/tasks/presentation/task_editor.dart';

class ReviewBinding extends WidgetsFlutterBinding {
  Size size = const Size(390, 844);
  @override
  ViewConfiguration createViewConfigurationFor(RenderView renderView) =>
      ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(size),
        physicalConstraints: BoxConstraints.tight(size),
        devicePixelRatio: 1,
      );
}

int passed = 0;
void check(bool value, String label) {
  if (!value) throw StateError('FAIL: $label');
  passed++;
  stdout.writeln('PASS: $label');
}

Map<String, dynamic> fixture({num temperature = 25}) => {
  'current': {
    'time': '2026-10-27T12:30',
    'temperature_2m': temperature,
    'relative_humidity_2m': 52,
    'wind_speed_10m': 11,
    'weather_code': 2,
    'apparent_temperature': 26,
    'is_day': 1,
  },
  'hourly': {
    'time': List.generate(
      24,
      (i) => '2026-10-27T${i.toString().padLeft(2, '0')}:00',
    ),
    'temperature_2m': List.generate(24, (i) => 21 + i % 6),
    'weather_code': List.generate(24, (i) => i % 3),
    'precipitation_probability': List.generate(24, (i) => i * 2),
  },
  'daily': {
    'time': List.generate(
      7,
      (i) => DateTime(2026, 10, 27 + i).toIso8601String().substring(0, 10),
    ),
    'temperature_2m_min': [17, 18, 16, 17, 18, 17, 16],
    'temperature_2m_max': [26, 27, 25, 26, 24, 25, 26],
    'weather_code': [2, 3, 61, 2, 0, 3, 61],
    'precipitation_probability_max': [20, 30, 60, 10, 0, 30, 70],
  },
};
Future<void> main() async {
  final binding = ReviewBinding();
  final errors = <FlutterErrorDetails>[];
  FlutterError.onError = (details) {
    errors.add(details);
    stderr.writeln(details);
  };
  try {
    // This tool is a test harness, never an application entry point.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    final dir = await Directory.systemTemp.createTemp('daybook-verify-');
    final db = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: '${dir.path}/test.db',
    );
    final cache = WeatherCache(db);
    final tasks = TaskRepository(db);
    for (final n in [25, 25.8]) {
      final w = Weather.fromJson(fixture(temperature: n));
      check(w.temperature == n.toDouble(), 'JSON handles $n');
      check(
        Weather.fromJson(w.toJson()).time == w.time,
        'Weather JSON round trip',
      );
    }
    var invalid = false;
    try {
      Weather.fromJson({'current': {}});
    } on FormatException {
      invalid = true;
    }
    check(invalid, 'Malformed readings rejected');
    check(
      describe(71) == 'Snow' &&
          describe(-1) == 'Unknown conditions' &&
          describe(999) == 'Unknown conditions',
      'WMO and unknown codes',
    );
    final api = WeatherApi(
      MockClient((request) async {
        check(
          request.url.queryParameters['latitude'] == '-2.5967',
          'Huye coordinates',
        );
        check(
          request.url.queryParameters['timezone'] == 'Africa/Kigali',
          'Explicit timezone',
        );
        return http.Response(jsonEncode(fixture()), 200);
      }),
    );
    check((await api.fetch(cities[1])).temperature == 25, 'HTTP JSON response');
    for (final response in [
      http.Response('busy', 503),
      http.Response('{}', 200),
    ]) {
      var failed = false;
      try {
        await WeatherApi(MockClient((_) async => response)).fetch(cities.first);
      } catch (_) {
        failed = true;
      }
      check(
        failed,
        'HTTP status ${response.statusCode} invalid response rejected',
      );
    }
    var timedOut = false;
    try {
      await WeatherApi(
        MockClient((_) => Completer<http.Response>().future),
        timeout: const Duration(milliseconds: 10),
      ).fetch(cities.first);
    } on TimeoutException {
      timedOut = true;
    }
    check(timedOut, 'Slow request times out');
    final samples = await tasks.load();
    check(samples.length == 3, 'First-run samples');
    final task = Task(
      id: 'test-new',
      title: 'Read chapter',
      notes: 'A useful note',
      priority: 2,
      due: DateTime(2027, 1, 2),
    );
    await tasks.save(task);
    await tasks.save(task.copyWith(title: 'Read chapter two', done: true));
    await tasks.delete(samples.first);
    await db.close();
    final reopened = await tasks.load();
    check(
      reopened.firstWhere((t) => t.id == task.id).title == 'Read chapter two',
      'Edit survives database reopen',
    );
    check(
      reopened.firstWhere((t) => t.id == task.id).done,
      'Completion survives database reopen',
    );
    check(
      !reopened.any((t) => t.id == samples.first.id),
      'Delete survives database reopen',
    );
    final savedTask = reopened.firstWhere((t) => t.id == task.id);
    check(
      savedTask.notes == 'A useful note' && savedTask.priority == 2,
      'Notes and priority survive reopen',
    );
    check(savedTask.due == DateTime(2027, 1, 2), 'Due date survives reopen');
    check(await tasks.canUndo, 'Undo available after restart');
    await tasks.undoDelete();
    await db.close();
    check(
      (await tasks.load()).any((t) => t.id == samples.first.id),
      'Undo survives reopen',
    );
    await cache.save(cities.first, Weather.fromJson(fixture()));
    await cache.save(cities[1], Weather.fromJson(fixture(temperature: 19)));
    await db.close();
    check(
      (await cache.read(cities.first))!.temperature == 25 &&
          (await cache.read(cities[1]))!.temperature == 19,
      'Per-city caches survive reopen',
    );
    check(
      await cache.read(cities[2]) == null,
      'Unvisited city has no fabricated cache',
    );
    var online = false;
    final weather = WeatherController(cache, (_) async {
      if (!online) throw const SocketException('offline');
      return Weather.fromJson(fixture());
    });
    await weather.start();
    check(
      weather.offline && weather.weather != null && !weather.loading,
      'Cached offline state',
    );
    await weather.select(cities[2]);
    check(
      weather.error != null && weather.weather == null && !weather.loading,
      'Uncached offline error',
    );
    online = true;
    await weather.load();
    check(
      weather.error == null && !weather.offline && weather.weather != null,
      'Retry recovers',
    );
    check(
      (await SharedPreferences.getInstance()).getString('city') == 'Musanze',
      'City saved',
    );
    final restored = WeatherController(
      cache,
      (_) async => Weather.fromJson(fixture()),
    );
    await restored.start();
    check(restored.city.name == 'Musanze', 'City restored before fetching');
    restored.dispose();
    final slow = Completer<Weather>();
    final race = WeatherController(
      cache,
      (city) => city == cities.first
          ? slow.future
          : Future.value(Weather.fromJson(fixture(temperature: 18))),
    );
    final oldRequest = race.load();
    await race.select(cities[1]);
    slow.complete(Weather.fromJson(fixture(temperature: 30)));
    await oldRequest;
    check(
      race.city.name == 'Huye' && race.weather!.temperature == 18,
      'Old response cannot overwrite selected city',
    );
    race.dispose();
    final controller = TaskController(tasks);
    await controller.load();
    controller.search('useful note');
    controller.setFilter(TaskFilter.completed);
    check(
      controller.visible.length == 1,
      'Search covers notes and completed filter',
    );
    controller.search('');
    controller.setFilter(TaskFilter.all);
    check(
      controller.visible.every((t) => !t.done),
      'All tasks excludes completed',
    );

    final boundaryKey = GlobalKey();
    Future<void> capture(
      String name,
      Widget screen, {
      double scale = 1,
      double scrollOffset = 0,
    }) async {
      runApp(
        RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: screen,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      binding.scheduleWarmUpFrame();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (scrollOffset > 0) {
        void scroll(Element element) {
          if (element is StatefulElement && element.state is ScrollableState) {
            final state = element.state as ScrollableState;
            if (state.position.axis == Axis.vertical) {
              state.position.jumpTo(
                scrollOffset.clamp(0, state.position.maxScrollExtent),
              );
            }
          }
          element.visitChildElements(scroll);
        }

        scroll(binding.rootElement!);
        binding.scheduleWarmUpFrame();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('../docs/screenshots').create(recursive: true);
      await File('../docs/screenshots/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      check(errors.isEmpty, '$name renders without Flutter errors');
    }

    await weather.select(cities.first);
    await capture('weather', WeatherScreen(controller: weather));
    await capture(
      'weather-details',
      WeatherScreen(controller: weather),
      scrollOffset: 900,
    );
    await capture(
      'daybook',
      TaskScreen(controller: controller, weather: weather),
    );
    Element locate(bool Function(Widget) predicate) {
      Element? found;
      void visit(Element element) {
        if (predicate(element.widget)) found ??= element;
        element.visitChildElements(visit);
      }

      visit(binding.rootElement!);
      if (found == null) throw StateError('Widget not found');
      return found!;
    }

    Future<void> settle() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      binding.scheduleWarmUpFrame();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    Future<void> tapText(String label) async {
      final element = locate((w) => w is Text && w.data == label);
      final box = element.findRenderObject()! as RenderBox;
      final point = box.localToGlobal(box.size.center(Offset.zero));
      binding.handlePointerEvent(PointerDownEvent(pointer: 1, position: point));
      binding.handlePointerEvent(PointerUpEvent(pointer: 1, position: point));
      await settle();
    }

    await tapText('New task');
    final titleField =
        locate((w) => w is TextFormField && w.key == const Key('task-title'))
                .widget
            as TextFormField;
    titleField.controller!.text = 'Created through the task sheet';
    final noteField =
        locate((w) => w is TextFormField && w.key == const Key('task-notes'))
                .widget
            as TextFormField;
    noteField.controller!.text = 'Notes saved from the real form';
    await tapText('Add task');
    check(
      controller.tasks.any(
        (t) =>
            t.title == 'Created through the task sheet' &&
            t.notes == 'Notes saved from the real form',
      ),
      'Real pointer taps create task through form',
    );
    controller.search('Created through');
    await settle();
    await tapText('Created through the task sheet');
    final editing =
        locate((w) => w is TextFormField && w.key == const Key('task-title'))
                .widget
            as TextFormField;
    editing.controller!.text = 'Edited through the task sheet';
    await tapText('Save changes');
    check(
      controller.tasks.any((t) => t.title == 'Edited through the task sheet'),
      'Real pointer taps edit task through form',
    );
    controller.search('');

    await capture(
      'task-editor',
      Scaffold(
        body: TaskEditor(controller: controller, task: samples.first),
      ),
    );
    online = false;
    await weather.load();
    await capture('weather-offline', WeatherScreen(controller: weather));
    var misleadingLabel = false;
    void inspectSavedLabels(Element element) {
      final widget = element.widget;
      if (widget is Text && (widget.data == 'Now' || widget.data == 'Today')) {
        misleadingLabel = true;
      }
      element.visitChildElements(inspectSavedLabels);
    }

    inspectSavedLabels(binding.rootElement!);
    check(!misleadingLabel, 'Cached forecast does not claim Now or Today');

    final empty = WeatherController(
      cache,
      (_) async => throw const SocketException('offline'),
    );
    await empty.select(cities[3]);
    await capture('weather-error', WeatherScreen(controller: empty));
    empty.dispose();
    await capture(
      'weather-large-text',
      WeatherScreen(controller: weather),
      scale: 1.6,
    );
    await capture(
      'daybook-large-text',
      TaskScreen(controller: controller, weather: weather),
      scale: 1.6,
    );
    for (final t in await tasks.load()) {
      await tasks.delete(t);
    }
    await db.close();
    check(
      (await tasks.load()).isEmpty,
      'Empty list stays empty; samples not reseeded',
    );
    await controller.load();
    await capture(
      'daybook-empty',
      TaskScreen(controller: controller, weather: weather),
    );
    controller.dispose();
    weather.dispose();
    await db.close();
    await dir.delete(recursive: true);
    await generateIcons();
    check(true, 'Both app icon sets generated');
    stdout.writeln(
      'VERIFIED: $passed checks passed. Screenshots use deterministic test data.',
    );
    exit(0);
  } catch (error, stack) {
    stderr.writeln('$error\n$stack');
    exit(1);
  }
}
