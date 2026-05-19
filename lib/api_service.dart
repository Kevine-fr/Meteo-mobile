import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static const String apiKey = 'c77b620170a24242bdd140558243103';
  static const String baseUrl = 'https://api.weatherapi.com/v1/forecast.json';

  Future<Map<String, dynamic>> fetch(String query) async {
    final url = Uri.parse(
      '$baseUrl?key=$apiKey&q=$query&days=7&aqi=yes&alerts=yes&lang=fr',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw WeatherException(
      response.statusCode == 400
          ? 'Ville introuvable'
          : 'Erreur réseau (${response.statusCode})',
    );
  }

  Future<Map<String, dynamic>> fetchByCoords(double lat, double lon) =>
      fetch('$lat,$lon');

  Future<Map<String, dynamic>> fetchByCity(String city) => fetch(city);
}

class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);
  @override
  String toString() => message;
}

/// =====================================================
///  GÉOLOCALISATION
/// =====================================================
class LocationService {
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
      );
    } catch (_) {
      return null;
    }
  }
}
