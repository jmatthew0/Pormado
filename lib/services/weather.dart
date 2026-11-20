import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Philippine cities offered in the weather screen.
class PhCity {
  final String name;
  final double lat, lon;
  const PhCity(this.name, this.lat, this.lon);
}

const phCities = <PhCity>[
  PhCity('Manila', 14.5995, 120.9842),
  PhCity('Quezon City', 14.6760, 121.0437),
  PhCity('Calamba', 14.2117, 121.1653),
  PhCity('Baguio', 16.4023, 120.5960),
  PhCity('Cebu City', 10.3157, 123.8854),
  PhCity('Iloilo City', 10.7202, 122.5621),
  PhCity('Davao City', 7.1907, 125.4553),
];

IconData iconForCode(int c) {
  if (c == 0) return Icons.wb_sunny_rounded;
  if (c <= 2) return Icons.wb_cloudy_rounded;
  if (c <= 48) return Icons.cloud_rounded;
  if (c >= 95) return Icons.thunderstorm_rounded;
  return Icons.water_drop_rounded;
}

String labelForCode(int c) {
  if (c == 0) return 'Clear';
  if (c <= 2) return 'Partly cloudy';
  if (c == 3) return 'Overcast';
  if (c <= 48) return 'Foggy';
  if (c <= 57) return 'Drizzle';
  if (c <= 67) return 'Rain';
  if (c >= 80 && c <= 82) return 'Showers';
  if (c >= 95) return 'Thunderstorms';
  return 'Cloudy';
}

Color colorForCode(int c) {
  if (c == 0 || c <= 2) return const Color(0xFFE0AE4F);
  if (c <= 48) return const Color(0xFF8B8883);
  return const Color(0xFF6C7F8F);
}

class HourSlot {
  final String label;
  final int temp, code, rain;
  const HourSlot(this.label, this.temp, this.code, this.rain);
}

class Weather {
  final String city;
  final int temp, feels, high, low, humidity, wind, code, rainMax;
  final String rainHour;
  final List<HourSlot> hours;
  final DateTime updated;
  final bool offline;

  const Weather({
    required this.city,
    required this.temp,
    required this.feels,
    required this.high,
    required this.low,
    required this.humidity,
    required this.wind,
    required this.code,
    required this.rainMax,
    required this.rainHour,
    required this.hours,
    required this.updated,
    this.offline = false,
  });

  bool get rainy => rainMax >= 50;
  String get condition => labelForCode(code);
  String get summary =>
      rainy ? '$condition · Rain around $rainHour' : condition;

  String get tip {
    if (rainy) return 'Pack a rain jacket for $rainHour';
    if (feels >= 34) return 'Go breathable – it feels like $feels°';
    if (temp <= 22) return 'Add a light layer – it\'s cool out';
    return 'Easy day – light layers will do';
  }

  String get adviceTitle {
    if (rainy) return 'Layer up and bring an umbrella';
    if (feels >= 34) return 'Keep it light and breathable';
    if (temp <= 22) return 'Add a layer';
    return 'Easy, comfortable day';
  }

  String get adviceBody {
    if (rainy) {
      return 'Rain is likely around $rainHour ($rainMax%). Waterproof outerwear and closed shoes (or slides that can get wet) are the smart pick.';
    }
    if (feels >= 34) {
      return 'It feels like $feels° with $humidity% humidity. Choose linen or cotton and skip heavy layers.';
    }
    if (temp <= 22) {
      return 'Temperatures dip to $low°. A light jacket or knit works well.';
    }
    return 'Conditions are mild. Most of your wardrobe will work today.';
  }

  static Weather fallback(PhCity c) {
    final now = DateTime.now();
    String h(int k) =>
        k == 0 ? 'Now' : DateFormat('h a').format(now.add(Duration(hours: k)));
    return Weather(
      city: c.name,
      temp: 31,
      feels: 36,
      high: 33,
      low: 25,
      humidity: 74,
      wind: 11,
      code: 2,
      rainMax: 60,
      rainHour: '4 PM',
      hours: [
        HourSlot(h(0), 31, 2, 10),
        HourSlot(h(3), 33, 2, 30),
        HourSlot(h(6), 29, 61, 60),
        HourSlot(h(9), 27, 3, 20),
        HourSlot(h(12), 26, 3, 10),
      ],
      updated: now,
      offline: true,
    );
  }

  static Future<Weather> fetch(PhCity c) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${c.lat}',
      'longitude': '${c.lon}',
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
      'hourly': 'temperature_2m,weather_code,precipitation_probability',
      'daily': 'temperature_2m_max,temperature_2m_min',
      'timezone': 'auto',
      'forecast_days': '2',
    });
    final r = await http.get(uri).timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) throw Exception('Weather ${r.statusCode}');
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final cur = j['current'] as Map<String, dynamic>;
    final hourly = j['hourly'] as Map<String, dynamic>;
    final daily = j['daily'] as Map<String, dynamic>;
    final times = (hourly['time'] as List).cast<String>();
    final temps = (hourly['temperature_2m'] as List);
    final codes = (hourly['weather_code'] as List);
    final probs = (hourly['precipitation_probability'] as List);

    final nowKey = (cur['time'] as String).substring(0, 13);
    var idx = times.indexWhere((t) => t.startsWith(nowKey));
    if (idx < 0) idx = 0;

    int numAt(List l, int i) => ((l[i] ?? 0) as num).round();

    final hours = <HourSlot>[];
    for (final k in [0, 3, 6, 9, 12]) {
      final i = idx + k;
      if (i >= times.length) break;
      hours.add(HourSlot(
        k == 0 ? 'Now' : DateFormat('h a').format(DateTime.parse(times[i])),
        numAt(temps, i),
        numAt(codes, i),
        numAt(probs, i),
      ));
    }

    var maxP = 0;
    var maxI = idx;
    for (var i = idx; i < min(idx + 13, times.length); i++) {
      final p = numAt(probs, i);
      if (p > maxP) {
        maxP = p;
        maxI = i;
      }
    }

    return Weather(
      city: c.name,
      temp: (cur['temperature_2m'] as num).round(),
      feels: (cur['apparent_temperature'] as num).round(),
      high: ((daily['temperature_2m_max'] as List).first as num).round(),
      low: ((daily['temperature_2m_min'] as List).first as num).round(),
      humidity: (cur['relative_humidity_2m'] as num).round(),
      wind: (cur['wind_speed_10m'] as num).round(),
      code: (cur['weather_code'] as num).round(),
      rainMax: maxP,
      rainHour: DateFormat('h a').format(DateTime.parse(times[maxI])),
      hours: hours,
      updated: DateTime.now(),
    );
  }
}
