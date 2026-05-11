import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// Theme mode state notifier
class ThemeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;

  ThemeNotifier(this._storage)
      : super(_storage.isDarkMode ? ThemeMode.dark : ThemeMode.light);

  bool get isDark => state == ThemeMode.dark;

  Future<void> toggle() async {
    final newMode =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    await _storage.setDarkMode(newMode == ThemeMode.dark);
  }

  Future<void> setDark(bool dark) async {
    state = dark ? ThemeMode.dark : ThemeMode.light;
    await _storage.setDarkMode(dark);
  }
}

/// Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  // Uses the singleton StorageService (already initialized in main)
  final storage = StorageService();
  return ThemeNotifier(storage);
});
