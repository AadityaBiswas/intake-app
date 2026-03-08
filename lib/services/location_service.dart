import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _locationCacheKey = 'cached_user_location';
  static const String _locationTimestampKey = 'cached_user_location_timestamp';
  // Cache the location for 1.5 hours
  static const Duration _cacheDuration = Duration(minutes: 90);

  Future<void> requestPermissionAndFetchLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return; 
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return; 
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return; 
    }

    await _fetchAndCacheLocation();
  }

  Future<void> _fetchAndCacheLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String locationString = '';
        if (place.locality != null && place.locality!.isNotEmpty) {
           locationString += place.locality!;
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
           locationString += (locationString.isNotEmpty ? ', ' : '') + place.administrativeArea!;
        }
        if (place.country != null && place.country!.isNotEmpty && locationString.isEmpty) {
           locationString = place.country!;
        }

        if (locationString.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_locationCacheKey, locationString);
          await prefs.setString(_locationTimestampKey, DateTime.now().toIso8601String());
        }
      }
    } catch (e) {
      // Fail silently, AI will just fallback to generic data
    }
  }

  Future<String?> getCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedLocation = prefs.getString(_locationCacheKey);
    final timestampStr = prefs.getString(_locationTimestampKey);

    if (cachedLocation != null && timestampStr != null) {
      try {
        final timestamp = DateTime.parse(timestampStr);
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          return cachedLocation;
        }
      } catch (e) {
        // Ignore parse errors
      }
    }

    // Cache expired or missing, try to fetch quietly
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        await _fetchAndCacheLocation();
        return prefs.getString(_locationCacheKey);
    }
    
    return null; // Return null if we don't have permission 
  }
}
