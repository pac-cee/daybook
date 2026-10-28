import 'package:http/http.dart' as http;

import 'app_database.dart';
import '../features/weather/data/weather_api.dart';
import '../features/weather/data/weather_repository.dart';
import '../features/weather/presentation/weather_controller.dart';
import '../features/tasks/data/task_repository.dart';

class AppServices {
  AppServices({AppDatabase? database, http.Client? client})
    : database = database ?? AppDatabase(),
      client = client ?? http.Client();
  final AppDatabase database;
  final http.Client client;
  late final WeatherController weather = WeatherController(
    WeatherCache(database),
    WeatherApi(client).fetch,
  );
  late final TaskRepository tasks = TaskRepository(database);
  void dispose() {
    weather.dispose();
    client.close();
    database.close();
  }
}
