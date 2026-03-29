import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  static const String _locationCacheKey = 'cached_user_location';
  static const String _locationTimestampKey = 'cached_user_location_timestamp';
  static const String _onboardingRegionKey = 'onboarding_region';
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String locationString = '';
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          locationString += place.subLocality!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          locationString +=
              (locationString.isNotEmpty ? ', ' : '') + place.locality!;
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          locationString +=
              (locationString.isNotEmpty ? ', ' : '') +
              place.administrativeArea!;
        }
        if (place.country != null && place.country!.isNotEmpty) {
          locationString +=
              (locationString.isNotEmpty ? ', ' : '') + place.country!;
        }

        if (locationString.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_locationCacheKey, locationString);
          await prefs.setString(
            _locationTimestampKey,
            DateTime.now().toIso8601String(),
          );
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
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await _fetchAndCacheLocation();
      return prefs.getString(_locationCacheKey);
    }

    return null; // Return null if we don't have permission
  }

  /// Fetches the user's onboarding region from Firestore and caches it locally.
  /// Returns the region string (e.g. "South Asia") or null.
  Future<String?> getOnboardingRegion() async {
    final prefs = await SharedPreferences.getInstance();

    // Check local cache first
    final cached = prefs.getString(_onboardingRegionKey);
    if (cached != null && cached.isNotEmpty) return cached;

    // Fetch from Firestore
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final region = doc.data()?['region'] as String?;
      if (region != null && region.isNotEmpty) {
        await prefs.setString(_onboardingRegionKey, region);
        return region;
      }
    } catch (e) {
      // Fail silently
    }
    return null;
  }

  /// Returns the best available location string for AI context:
  /// 1. Dynamic GPS location (most specific — includes sub-locality, city, state, country)
  /// 2. Onboarding region (broad fallback like "South Asia")
  /// Returns null only if neither is available.
  Future<String?> getEffectiveLocation() async {
    final gpsLocation = await getCachedLocation();
    if (gpsLocation != null && gpsLocation.isNotEmpty) return gpsLocation;
    return getOnboardingRegion();
  }
}
