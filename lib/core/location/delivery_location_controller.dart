import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/connectivity_sync_service.dart';

/// GPS + reverse geocode for header "Deliver to" and address form autofill (quick-commerce style).
class DeliveryLocationController extends GetxController {
  DeliveryLocationController(this._prefs);

  final SharedPreferences _prefs;

  static const _kLat = 'delivery_loc_lat';
  static const _kLng = 'delivery_loc_lng';
  static const _kPrimary = 'delivery_loc_primary';
  static const _kSecondary = 'delivery_loc_secondary';

  /// Area / locality (e.g. neighbourhood).
  final primaryLine = ''.obs;

  /// City, state (short).
  final secondaryLine = ''.obs;

  final isLocating = false.obs;

  double? get latitude => _prefs.getDouble(_kLat);
  double? get longitude => _prefs.getDouble(_kLng);

  @override
  void onReady() {
    super.onReady();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    _loadCache();
    await refreshFromGps();
  }

  void _loadCache() {
    primaryLine.value = _prefs.getString(_kPrimary) ?? '';
    secondaryLine.value = _prefs.getString(_kSecondary) ?? '';
  }

  Future<void> _persist(Placemark p, double lat, double lng) async {
    final primary = _areaTitle(p);
    final secondary = _cityStateLine(p);
    primaryLine.value = primary;
    secondaryLine.value = secondary;
    await _prefs.setDouble(_kLat, lat);
    await _prefs.setDouble(_kLng, lng);
    await _prefs.setString(_kPrimary, primary);
    await _prefs.setString(_kSecondary, secondary);
  }

  /// Call when online + permission; updates header and cache.
  Future<void> refreshFromGps() async {
    final net = Get.find<ConnectivitySyncService>();
    if (!net.isOnline.value) {
      _loadCache();
      return;
    }

    isLocating.value = true;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _loadCache();
        return;
      }

      final service = await Geolocator.isLocationServiceEnabled();
      if (!service) {
        _loadCache();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isEmpty) return;
      await _persist(marks.first, pos.latitude, pos.longitude);
    } on Object catch (_) {
      _loadCache();
    } finally {
      isLocating.value = false;
    }
  }

  /// Build prefill from last cached coordinates (reverse geocode).
  Future<Map<String, String>> fetchPrefillMap() async {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return {};
    try {
      final marks = await placemarkFromCoordinates(lat, lng);
      if (marks.isEmpty) return {};
      return placemarkToAddressMap(marks.first);
    } on Object catch (_) {
      return {};
    }
  }
}

String _areaTitle(Placemark p) {
  final a = [
    p.subLocality,
    p.locality,
    p.name,
    p.subAdministrativeArea,
  ].whereType<String>().where((e) => e.trim().isNotEmpty).toList();
  return a.isNotEmpty ? a.first : 'Current location';
}

String _cityStateLine(Placemark p) {
  final city = p.locality ?? p.subAdministrativeArea ?? '';
  final state = p.administrativeArea ?? '';
  if (city.isEmpty && state.isEmpty) return p.country ?? '';
  if (city.isEmpty) return state;
  if (state.isEmpty) return city;
  return '$city, $state';
}

/// Flatten [Placemark] into address form fields (Blinkit-style autofill).
Map<String, String> placemarkToAddressMap(Placemark p) {
  final line1 = [
    p.subThoroughfare,
    p.thoroughfare,
    p.street,
  ].whereType<String>().where((e) => e.trim().isNotEmpty).join(', ');
  final line1Final = line1.isNotEmpty
      ? line1
      : [
          p.name,
          p.subLocality,
        ].whereType<String>().where((e) => e.trim().isNotEmpty).join(', ');

  return {
    'line1': line1Final,
    'line2': p.subLocality != null &&
            p.subLocality != p.locality &&
            (p.subLocality?.isNotEmpty ?? false)
        ? p.subLocality!
        : '',
    'landmark': '',
    'city': p.locality ?? p.subAdministrativeArea ?? '',
    'state': p.administrativeArea ?? '',
    'pincode': p.postalCode ?? '',
  };
}
