import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'weather.dart';

/// Finds where the phone is right now and names the place.
class LocationService {
  /// Returns null when location is off or permission is denied.
  static Future<PhCity?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 12)),
      );
      final name = await _placeName(pos.latitude, pos.longitude);
      return PhCity(name, pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  static Future<String> _placeName(double lat, double lon) async {
    try {
      final uri =
          Uri.https('api.bigdatacloud.net', '/data/reverse-geocode-client', {
        'latitude': '$lat',
        'longitude': '$lon',
        'localityLanguage': 'en',
      });
      final r = await http.get(uri).timeout(const Duration(seconds: 8));
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      for (final k in ['city', 'locality', 'principalSubdivision']) {
        final v = j[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    } catch (_) {}
    return 'Your location';
  }
}
