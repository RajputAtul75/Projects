import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert_model.dart';
import '../services/storage_service.dart';

/// Alert state notifier — manages in-memory alert list
class AlertNotifier extends StateNotifier<List<AlertModel>> {
  final StorageService _storage;

  AlertNotifier(this._storage) : super([]) {
    _loadAlerts();
  }

  void _loadAlerts() {
    final cached = _storage.getCachedAlerts();
    state = cached ?? AlertModel.dummyAlerts();
  }

  /// Mark alert as read
  void markRead(String id) {
    state = [
      for (final alert in state)
        if (alert.id == id) alert.copyWith(isRead: true) else alert,
    ];
    _storage.cacheAlerts(state);
  }

  /// Mark all alerts as read
  void markAllRead() {
    state = state.map((a) => a.copyWith(isRead: true)).toList();
    _storage.cacheAlerts(state);
  }

  /// Add a new alert
  void addAlert(AlertModel alert) {
    state = [alert, ...state];
    _storage.cacheAlerts(state);
  }

  /// Remove an alert
  void removeAlert(String id) {
    state = state.where((a) => a.id != id).toList();
    _storage.cacheAlerts(state);
  }

  /// Clear all alerts
  void clearAll() {
    state = [];
    _storage.cacheAlerts(state);
  }

  int get unreadCount => state.where((a) => !a.isRead).length;
}

final alertProvider =
    StateNotifierProvider<AlertNotifier, List<AlertModel>>((ref) {
  return AlertNotifier(StorageService()); // singleton, already initialized
});

/// Unread count provider
final unreadAlertCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(alertProvider);
  return alerts.where((a) => !a.isRead).length;
});
