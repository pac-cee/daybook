// Native simulator evidence. Run before and after as separate Flutter processes.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:kigali_weather/core/services.dart';
import 'package:kigali_weather/core/theme.dart';
import 'package:kigali_weather/features/tasks/presentation/task_controller.dart';
import 'package:kigali_weather/features/tasks/presentation/task_screen.dart';
import 'package:kigali_weather/features/weather/data/weather_api.dart';
import 'package:kigali_weather/features/weather/data/weather_repository.dart';
import 'package:kigali_weather/features/weather/domain/weather.dart';
import 'package:kigali_weather/features/weather/presentation/weather_controller.dart';
import 'package:kigali_weather/features/weather/presentation/weather_screen.dart';
import 'package:kigali_weather/core/app_database.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const phase = String.fromEnvironment(
    'SUBMISSION_PHASE',
    defaultValue: 'before',
  );
  const titles = [
    'Review async and await',
    'Finish the Daybook README',
    'Submit the repository link',
  ];
  testWidgets('Daybook submission evidence: $phase', (tester) async {
    final services = AppServices();
    final controller = TaskController(services.tasks);
    await controller.load();
    await services.weather.start();
    expect(
      services.weather.error,
      isNull,
      reason: 'Submission needs a real live API response.',
    );
    expect(
      services.weather.offline,
      false,
      reason: 'Cached weather is not live evidence.',
    );
    final evidence = Directory(
      '${Directory.systemTemp.path}/daybook-submission',
    );
    await evidence.create(recursive: true);
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      final bytes = await binding.takeScreenshot(name);
      await File('${evidence.path}/$name.png').writeAsBytes(bytes);
    }

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        home: TaskScreen(controller: controller, weather: services.weather),
      ),
    );
    await tester.pumpAndSettle();
    if (phase == 'before') {
      for (var i = 0; i < titles.length; i++) {
        if (controller.tasks.any((task) => task.title == titles[i])) continue;
        await tester.tap(find.text('New task'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('task-title')), titles[i]);
        await tester.enterText(
          find.byKey(const Key('task-notes')),
          const [
            'Group B · Explain Futures and error handling.',
            'Group B · Add the four required screenshots.',
            'Group B · Due 28 October at 11:59 PM.',
          ][i],
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Add task'));
        await tester.tap(find.text('Add task'));
        await tester.pumpAndSettle();
        for (var attempt = 0; attempt < 30 && controller.busy; attempt++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(controller.tasks.any((task) => task.title == titles[i]), true);
      }
      final rows = controller.tasks
          .where((t) => titles.contains(t.title))
          .map((t) => t.toJson())
          .toList();
      await File('${evidence.path}/before-records.json')
          .writeAsString(jsonEncode(rows));
    } else {
      final before = jsonDecode(
        await File('${evidence.path}/before-records.json').readAsString(),
      ) as List;
      for (final row in before) {
        final task = controller.tasks.singleWhere((t) => t.id == row['id']);
        expect(
          task.toJson(),
          row,
          reason: 'Every field must survive a separate process launch.',
        );
      }
      expect(before.length, 3);
    }
    final search = find.byType(TextField).first;
    await tester.enterText(search, 'Group B');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final outer = find.byType(Scrollable).first;
    final scroll = tester.state<ScrollableState>(outer);
    await Scrollable.ensureVisible(tester.element(search), alignment: 0);
    scroll.position.jumpTo(
      (scroll.position.pixels - 16).clamp(0.0, scroll.position.maxScrollExtent),
    );
    await tester.pumpAndSettle();
    await capture(phase);
    if (phase == 'before') {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme(),
          home: WeatherScreen(controller: services.weather, canPop: true),
        ),
      );
      await tester.pumpAndSettle();
      await capture('api');
      await File('${evidence.path}/api-observation.json')
          .writeAsString(jsonEncode(services.weather.weather!.toJson()));
      // iOS Simulator shares the host network; it has no functional Airplane Mode.
      // Inject a transport failure while retaining the production controller and UI.
      final isolated = AppDatabase(
        path:
            '${Directory.systemTemp.path}/submission-offline-${DateTime.now().microsecondsSinceEpoch}.db',
      );
      var fail = true;
      final client = http.Client();
      final offline = WeatherController(WeatherCache(isolated), (city) async {
        if (fail) {
          throw const SocketException('Network unavailable for offline test');
        }
        return WeatherApi(client).fetch(city);
      });
      await offline.select(cities[3]);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme(),
          home: WeatherScreen(controller: offline, canPop: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      expect(offline.error, isNotNull);
      await capture('no-internet');
      fail = false;
      await tester.tap(find.text('Retry'));
      for (var i = 0; i < 150 && offline.loading; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(offline.error, isNull);
      expect(offline.weather, isNotNull);
      await tester.pumpWidget(const SizedBox());
      offline.dispose();
      client.close();
      await isolated.close();
    }
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    services.weather.dispose();
    services.client.close();
    await services.database.close();
  });
}
