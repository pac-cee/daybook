import 'package:flutter/material.dart';

import 'core/services.dart';
import 'core/theme.dart';
import 'features/weather/presentation/weather_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WeatherApp());
}

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});
  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  final services = AppServices();
  @override
  void initState() {
    super.initState();
    services.weather.start();
  }

  @override
  void dispose() {
    services.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Kigali Weather',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    home: WeatherScreen(controller: services.weather),
  );
}
