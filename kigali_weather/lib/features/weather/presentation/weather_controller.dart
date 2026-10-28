import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/weather_repository.dart';
import '../domain/weather.dart';

class WeatherController extends ChangeNotifier {
  WeatherController(this.cache, this.fetch);
  final WeatherCache cache;
  final Future<Weather> Function(City) fetch;
  City city = cities.first;
  Weather? weather;
  bool loading = true, offline = false;
  String? error, storageWarning;
  int _request = 0;
  bool _disposed = false;
  Future<void> _preferenceWrite = Future.value();

  Future<void> start() async {
    try {
      final name = (await SharedPreferences.getInstance()).getString('city');
      city = cities.where((c) => c.name == name).firstOrNull ?? cities.first;
    } catch (_) {
      storageWarning = 'Your city preference could not be read.';
    }
    if (!_disposed) await load();
  }

  Future<void> select(City selected) async {
    city = selected;
    // Queue settings writes so rapid selections persist in their original order.
    _preferenceWrite = _preferenceWrite.then((_) async {
      try {
        final saved = await (await SharedPreferences.getInstance()).setString(
          'city',
          selected.name,
        );
        if (!saved) throw StateError('Preference not saved');
      } catch (_) {
        storageWarning = 'Your city choice could not be saved.';
        _emit();
      }
    });
    await load();
    await _preferenceWrite;
  }

  Future<void> load() async {
    final request = ++_request;
    final selected = city;
    loading = true;
    error = null;
    offline = false;
    weather = null;
    _emit();
    try {
      final result = await fetch(selected);
      try {
        await cache.save(selected, result);
      } catch (_) {
        storageWarning =
            'Weather is live, but could not be saved for offline use.';
      }
      if (_disposed || request != _request) return;
      weather = result;
    } catch (_) {
      Weather? saved;
      try {
        saved = await cache.read(selected);
      } catch (_) {
        storageWarning = 'Saved weather could not be read.';
      }
      if (_disposed || request != _request) return;
      weather = saved;
      offline = saved != null;
      error = saved == null
          ? 'Could not load the weather. Check your internet connection and try again.'
          : null;
    }
    if (_disposed || request != _request) return;
    loading = false;
    _emit();
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    super.dispose();
  }
}
