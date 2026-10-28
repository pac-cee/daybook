class City {
  const City(this.name, this.latitude, this.longitude);
  final String name;
  final double latitude;
  final double longitude;
}

const cities = [
  City('Kigali', -1.9441, 30.0619),
  City('Huye', -2.5967, 29.7394),
  City('Musanze', -1.4998, 29.6344),
  City('Rubavu', -1.6792, 29.2585),
];

String describe(int code) => switch (code) {
  0 => 'Clear sky',
  1 || 2 => 'Partly cloudy',
  3 => 'Cloudy',
  45 || 48 => 'Fog',
  51 || 53 || 55 || 56 || 57 => 'Drizzle',
  61 || 63 || 65 || 66 || 67 => 'Rain',
  71 || 73 || 75 || 77 => 'Snow',
  80 || 81 || 82 => 'Rain showers',
  85 || 86 => 'Snow showers',
  95 || 96 || 99 => 'Thunderstorm',
  _ => 'Unknown conditions',
};

class HourForecast {
  const HourForecast(this.time, this.temperature, this.code, this.rain);
  final String time;
  final double temperature;
  final int code;
  final int rain;
}

class DayForecast {
  const DayForecast(this.date, this.low, this.high, this.code, this.rain);
  final String date;
  final double low;
  final double high;
  final int code;
  final int rain;
}

/// API times are wall-clock times in Africa/Kigali, never the device timezone.
class Weather {
  Weather._(
    this._json,
    this.temperature,
    this.humidity,
    this.wind,
    this.code,
    this.time,
    this.feelsLike,
    this.isDay,
    this.hours,
    this.days,
  );
  final Map<String, dynamic> _json;
  final double temperature, wind, feelsLike;
  final int humidity, code;
  final String time;
  final bool isDay;
  final List<HourForecast> hours;
  final List<DayForecast> days;
  String get clock => time.substring(11, 16);
  String get observedDate => time.substring(0, 10);

  factory Weather.fromJson(Map<String, dynamic> json) {
    try {
      final c = json['current'] as Map<String, dynamic>;
      final time = c['time'] as String;
      if (time.length < 16 || DateTime.tryParse(time) == null) {
        throw const FormatException('Invalid observation time');
      }
      double number(dynamic v) {
        if (v is! num || !v.isFinite) {
          throw const FormatException('Invalid reading');
        }
        return v.toDouble();
      }

      final temperature = number(c['temperature_2m']);
      final humidity = number(c['relative_humidity_2m']).toInt();
      if (humidity < 0 || humidity > 100) {
        throw const FormatException('Invalid humidity');
      }
      final hours = <HourForecast>[];
      final h = json['hourly'] as Map<String, dynamic>?;
      if (h != null) {
        final times = h['time'] as List;
        for (var i = 0; i < times.length; i++) {
          final t = times[i] as String;
          if (DateTime.tryParse(t) == null) {
            throw const FormatException('Invalid hour');
          }
          // Include the current hour and the next 23 hours.
          if (t.compareTo('${time.substring(0, 13)}:00') >= 0 &&
              hours.length < 24) {
            hours.add(
              HourForecast(
                t,
                number(h['temperature_2m'][i]),
                number(h['weather_code'][i]).toInt(),
                number(h['precipitation_probability'][i]).toInt(),
              ),
            );
          }
        }
      }
      final days = <DayForecast>[];
      final d = json['daily'] as Map<String, dynamic>?;
      if (d != null) {
        final dates = d['time'] as List;
        for (var i = 0; i < dates.length; i++) {
          final date = dates[i] as String;
          if (DateTime.tryParse(date) == null) {
            throw const FormatException('Invalid date');
          }
          days.add(
            DayForecast(
              date,
              number(d['temperature_2m_min'][i]),
              number(d['temperature_2m_max'][i]),
              number(d['weather_code'][i]).toInt(),
              number(d['precipitation_probability_max'][i]).toInt(),
            ),
          );
        }
      }
      return Weather._(
        json,
        temperature,
        humidity,
        number(c['wind_speed_10m']),
        number(c['weather_code']).toInt(),
        time,
        c['apparent_temperature'] == null
            ? temperature
            : number(c['apparent_temperature']),
        c['is_day'] != 0,
        List.unmodifiable(hours),
        List.unmodifiable(days),
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Incomplete weather response');
    }
  }
  Map<String, dynamic> toJson() => _json;
}
