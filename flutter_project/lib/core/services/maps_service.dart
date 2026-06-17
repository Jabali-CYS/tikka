import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapsService {
  static final MapsService _instance = MapsService._internal();
  factory MapsService() => _instance;
  MapsService._internal();

  // Replace this with your Google Maps API Key from Google Cloud Console
  final String _googleMapsApiKey = "AIzaSyCTKahQcheeVCTmuDPKlj9y0JcNRoDBCxM";

  /// Verify and request GPS location permissions from the user device
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return null;
      }

      // When permissions are granted, access current coordinate location
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error capturing GPS coordinates: $e');
      return null;
    }
  }

  /// Resolve LatLng coordinates into a human-readable street address using Google Geocoding API
  Future<String> resolveCoordinatesToAddress(double latitude, double longitude) async {
    if (_googleMapsApiKey == "YOUR_GOOGLE_MAPS_API_KEY_HERE" || _googleMapsApiKey.isEmpty) {
      // Return a simulated Amman address fallback if no API key is specified yet
      return "Amman, Jordan (Coordinates: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})";
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$_googleMapsApiKey&language=ar',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'].toString();
        }
      }
      return "Amman Street, Jordan";
    } catch (e) {
      debugPrint('Error during Google Geocoding resolution: $e');
      return "Amman, Jordan";
    }
  }
}
