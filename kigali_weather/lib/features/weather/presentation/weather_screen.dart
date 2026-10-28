import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../domain/weather.dart';
import 'weather_controller.dart';
import 'weather_widgets.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({
    super.key,
    required this.controller,
    this.canPop = false,
  });
  final WeatherController controller;
  final bool canPop;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(
          '${controller.city.name} Weather',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        automaticallyImplyLeading: canPop,
        actions: [
          IconButton(
            tooltip: 'About weather data',
            icon: const Icon(CupertinoIcons.info_circle, size: 22),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (context) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weather, with context.',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Forecast data by Open-Meteo (open-meteo.com), licensed under CC BY 4.0. Temperatures are in Celsius; wind is in km/h. All weather times are in Africa/Kigali (UTC+2).',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your last successful forecast is saved on this device. If a request fails, the saved forecast is clearly marked. Forecasts are estimates and can change.',
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: cities
                    .map(
                      (city) => ChoiceChip(
                        label: Text(city.name),
                        selected: city.name == controller.city.name,
                        showCheckmark: false,
                        selectedColor: ink,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: city.name == controller.city.name ? ink : line,
                        ),
                        labelStyle: TextStyle(
                          color: city.name == controller.city.name
                              ? Colors.white
                              : muted,
                          fontSize: 13,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 8,
                        ),
                        shape: const StadiumBorder(),
                        onSelected: (_) => controller.select(city),
                      ),
                    )
                    .toList(),
              ),
              if (controller.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 150),
                  child: Column(
                    children: [
                      CupertinoActivityIndicator(radius: 14),
                      SizedBox(height: 20),
                      Text(
                        'Finding your forecast…',
                        style: TextStyle(color: muted),
                      ),
                    ],
                  ),
                ),
              if (!controller.loading && controller.error != null)
                WeatherError(
                  message: controller.error!,
                  onRetry: controller.load,
                ),
              if (!controller.loading && controller.weather != null) ...[
                if (controller.offline)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Surface(
                      color: blueWash,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionLabel(
                            'Offline · saved weather',
                            CupertinoIcons.wifi_slash,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Showing ${controller.weather!.observedDate} at ${controller.weather!.clock}. Live weather is unavailable.',
                          ),
                          TextButton(
                            onPressed: controller.load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                WeatherHero(
                  city: controller.city,
                  weather: controller.weather!,
                  offline: controller.offline,
                ),
                if (controller.weather!.hours.isNotEmpty) ...[
                  HourlyCard(
                    weather: controller.weather!,
                    offline: controller.offline,
                  ),
                  const SizedBox(height: 16),
                ],
                if (controller.weather!.days.isNotEmpty) ...[
                  DailyCard(
                    weather: controller.weather!,
                    offline: controller.offline,
                  ),
                  const SizedBox(height: 16),
                ],
                WeatherMetrics(weather: controller.weather!),
                const SizedBox(height: 24),
                const Text(
                  'Forecast by Open-Meteo · CC BY 4.0\nPull down to refresh · Times in Kigali',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, height: 1.7, color: muted),
                ),
              ],
              if (controller.storageWarning != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    controller.storageWarning!,
                    style: const TextStyle(color: muted),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class WeatherError extends StatelessWidget {
  const WeatherError({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 64),
    child: Column(
      children: [
        const Icon(CupertinoIcons.wifi_slash, size: 42, color: accent),
        const SizedBox(height: 20),
        const Text(
          'A little out of reach.',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, height: 1.5),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(CupertinoIcons.arrow_clockwise, size: 18),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}
