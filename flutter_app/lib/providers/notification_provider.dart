import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

// ── State ───────────────────────────────────────────────
class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
  }) =>
      NotificationState(
        notifications: notifications ?? this.notifications,
        unreadCount: unreadCount ?? this.unreadCount,
        isLoading: isLoading ?? this.isLoading,
      );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiService _api;

  NotificationNotifier(this._api) : super(const NotificationState());

  Future<void> fetch(String societyId) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.get(ApiConfig.notifications, params: {'society_id': societyId});
      final countRes = await _api.get(ApiConfig.unreadCount, params: {'society_id': societyId});
      final notifs = (res.data as List).map((e) => NotificationModel.fromJson(e)).toList();
      state = NotificationState(
        notifications: notifs,
        unreadCount: countRes.data['count'] ?? 0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _api.put(ApiConfig.markRead(id));
      state = state.copyWith(
        notifications: state.notifications.map((n) => n.id == id ? n.copyWith(read: true) : n).toList(),
        unreadCount: (state.unreadCount - 1).clamp(0, 999),
      );
    } catch (_) {}
  }

  Future<void> markAllRead(String societyId) async {
    try {
      await _api.post(ApiConfig.markAllRead, data: null);
      state = state.copyWith(
        notifications: state.notifications.map((n) => n.copyWith(read: true)).toList(),
        unreadCount: 0,
      );
    } catch (_) {}
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return NotificationNotifier(api);
});
