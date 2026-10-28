import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../core/theme.dart';
import '../domain/weather.dart';

class WeatherHero extends StatelessWidget {
  const WeatherHero({
    super.key,
    required this.city,
    required this.weather,
    required this.offline,
  });
  final City city;
  final Weather weather;
  final bool offline;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        const Text(
          'RWANDA',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 3,
            color: muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          city.name,
          style: const TextStyle(
            fontSize: 32,
            letterSpacing: -1,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Icon(
          weatherIcon(weather.code, isDay: weather.isDay),
          size: 48,
          color: accent,
          semanticLabel: describe(weather.code),
        ),
        Semantics(
          label: '${weather.temperature.round()} degrees Celsius',
          excludeSemantics: true,
          child: Text(
            '${weather.temperature.round()}°',
            style: const TextStyle(
              fontSize: 112,
              height: 1.15,
              fontWeight: FontWeight.w200,
              letterSpacing: -7,
            ),
          ),
        ),
        Text(
          describe(weather.code),
          style: const TextStyle(fontSize: 19, color: muted),
        ),
        const SizedBox(height: 10),
        if (weather.days.isNotEmpty)
          Text(
            'H: ${weather.days.first.high.round()}°   L: ${weather.days.first.low.round()}°',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        const SizedBox(height: 16),
        Text(
          '${offline ? 'Saved observation' : 'Updated'} at ${weather.clock} · Kigali time',
          style: const TextStyle(fontSize: 12, color: muted),
        ),
      ],
    ),
  );
}

class HourlyCard extends StatelessWidget {
  const HourlyCard({super.key, required this.weather, this.offline = false});
  final Weather weather;
  final bool offline;
  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Hourly forecast', CupertinoIcons.clock),
        const SizedBox(height: 18),
        SizedBox(
          height:
              132 *
              math.max(1, MediaQuery.textScalerOf(context).scale(12) / 12),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: weather.hours.length,
            separatorBuilder: (_, _) => const SizedBox(width: 22),
            itemBuilder: (context, i) {
              final hour = weather.hours[i];
              final h = int.parse(hour.time.substring(11, 13));
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    i == 0 && !offline ? 'Now' : hour.time.substring(11, 16),
                    style: const TextStyle(fontSize: 13, color: muted),
                  ),
                  Icon(
                    weatherIcon(hour.code, isDay: h >= 6 && h < 18),
                    color: accent,
                    size: 25,
                    semanticLabel: describe(hour.code),
                  ),
                  Text(
                    '${hour.temperature.round()}°',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${hour.rain}%',
                    style: const TextStyle(fontSize: 11, color: accent),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class DailyCard extends StatelessWidget {
  const DailyCard({super.key, required this.weather, this.offline = false});
  final Weather weather;
  final bool offline;
  @override
  Widget build(BuildContext context) {
    final low = weather.days.map((d) => d.low).reduce(math.min);
    final high = weather.days.map((d) => d.high).reduce(math.max);
    final span = math.max(1.0, high - low);
    return Surface(
      child: Column(
        children: [
          const SectionLabel('7-day forecast', CupertinoIcons.calendar),
          const SizedBox(height: 12),
          ...weather.days.asMap().entries.map((entry) {
            final d = entry.value;
            final day = DateTime.parse(d.date);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      entry.key == 0 && !offline
                          ? 'Today'
                          : const [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ][day.weekday - 1],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    weatherIcon(d.code),
                    color: accent,
                    size: 22,
                    semanticLabel: describe(d.code),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 34,
                    child: Text(
                      '${d.low.round()}°',
                      style: const TextStyle(color: muted, fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) => Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: blueWash,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: (d.low - low) / span * box.maxWidth,
                              width: math.max(
                                5,
                                (d.high - d.low) / span * box.maxWidth,
                              ),
                              top: 0,
                              bottom: 0,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: .65),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${d.high.round()}°',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class WeatherMetrics extends StatelessWidget {
  const WeatherMetrics({super.key, required this.weather});
  final Weather weather;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide =
          constraints.maxWidth > 300 &&
          MediaQuery.textScalerOf(context).scale(16) < 26;
      final width = wide
          ? (constraints.maxWidth - 16) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _metric(
            width,
            'Humidity',
            CupertinoIcons.drop,
            '${weather.humidity}%',
            'Relative humidity',
          ),
          _metric(
            width,
            'Wind',
            CupertinoIcons.wind,
            '${weather.wind.round()}',
            'Kilometres per hour',
          ),
          _metric(
            width,
            'Feels like',
            CupertinoIcons.thermometer,
            '${weather.feelsLike.round()}°',
            'Apparent temperature',
          ),
          if (weather.days.isNotEmpty)
            _metric(
              width,
              'Rain chance',
              CupertinoIcons.umbrella,
              '${weather.days.first.rain}%',
              'Forecast maximum',
            ),
        ],
      );
    },
  );
  Widget _metric(
    double width,
    String title,
    IconData icon,
    String value,
    String detail,
  ) => SizedBox(
    width: width,
    child: Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title, icon),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w400,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(detail, style: const TextStyle(fontSize: 12, color: muted)),
        ],
      ),
    ),
  );
}
