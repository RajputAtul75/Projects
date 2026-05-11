import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/heat_data.dart';
import '../models/alert_model.dart';

/// Offline caching service using Hive & SharedPreferences (singleton)
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _heatDataBox = 'heat_data_cache';
  static const String _alertsBox = 'alerts_cache';

  Box<String>? _heatBox;
  Box<String>? _alertBox;
  SharedPreferences? _prefs;

  bool _initialized = false;

  /// Initialize SharedPreferences first (critical for theme), then Hive
  Future<void> init() async {
    if (_initialized) return;

    // SharedPreferences first — needed immediately for theme/settings
    _prefs = await SharedPreferences.getInstance();

    // Hive for caching — wrapped in try-catch so a Hive failure
    // doesn't block the entire app startup
    try {
      await Hive.initFlutter();
      _heatBox = await Hive.openBox<String>(_heatDataBox);
      _alertBox = await Hive.openBox<String>(_alertsBox);
    } catch (e) {
      debugPrint('StorageService: Hive init failed: $e');
    }

    _initialized = true;
  }

  // ─── Heat Data Cache ───

  Future<void> cacheHeatData(HeatData data) async {
    await _heatBox?.put('latest', jsonEncode(data.toJson()));
  }

  HeatData? getCachedHeatData() {
    final raw = _heatBox?.get('latest');
    if (raw == null) return null;
    return HeatData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> cacheHeatHistory(List<HeatData> history) async {
    final list = history.map((e) => jsonEncode(e.toJson())).toList();
    await _heatBox?.put('history', jsonEncode(list));
  }

  List<HeatData>? getCachedHeatHistory() {
    final raw = _heatBox?.get('history');
    if (raw == null) return null;
    final list = (jsonDecode(raw) as List<dynamic>).cast<String>();
    return list
        .map((e) => HeatData.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  // ─── Alerts Cache ───

  Future<void> cacheAlerts(List<AlertModel> alerts) async {
    final list = alerts.map((e) => jsonEncode(e.toJson())).toList();
    await _alertBox?.put('alerts', jsonEncode(list));
  }

  List<AlertModel>? getCachedAlerts() {
    final raw = _alertBox?.get('alerts');
    if (raw == null) return null;
    final list = (jsonDecode(raw) as List<dynamic>).cast<String>();
    return list
        .map(
            (e) => AlertModel.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  // ─── Settings ───

  bool get isDarkMode => _prefs?.getBool('dark_mode') ?? false;
  Future<void> setDarkMode(bool value) async =>
      await _prefs?.setBool('dark_mode', value);

  bool get notificationsEnabled =>
      _prefs?.getBool('notifications') ?? true;
  Future<void> setNotificationsEnabled(bool value) async =>
      await _prefs?.setBool('notifications', value);

  double get alertThreshold =>
      _prefs?.getDouble('alert_threshold') ?? 0.75;
  Future<void> setAlertThreshold(double value) async =>
      await _prefs?.setDouble('alert_threshold', value);

  bool get backgroundLocationEnabled =>
      _prefs?.getBool('bg_location') ?? false;
  Future<void> setBackgroundLocationEnabled(bool value) async =>
      await _prefs?.setBool('bg_location', value);

  bool get onboardingComplete =>
      _prefs?.getBool('onboarding_complete') ?? false;
  Future<void> setOnboardingComplete(bool value) async =>
      await _prefs?.setBool('onboarding_complete', value);
}
