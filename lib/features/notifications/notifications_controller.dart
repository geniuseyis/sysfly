import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/key_value_store.dart';
import '../../data/repositories/providers.dart';
import '../../shared/models/models.dart';

/// Alerts with their read state. Read ids are persisted so alerts stay read
/// across launches.
class NotificationsController extends AsyncNotifier<List<AppNotification>> {
  KeyValueStore get _store => ref.read(keyValueStoreProvider);

  @override
  Future<List<AppNotification>> build() async {
    final items = await ref.watch(notificationRepositoryProvider).fetch();
    final read = _store.getStringList(StorageKeys.readNotifications).toSet();
    return [for (final n in items) read.contains(n.id) ? n.copyWith(read: true) : n];
  }

  Future<void> _persist(List<AppNotification> items) =>
      _store.setStringList(StorageKeys.readNotifications, [for (final n in items) if (n.read) n.id]);

  Future<void> markRead(String id) async {
    final items = state.valueOrNull;
    if (items == null) return;
    final next = [for (final n in items) n.id == id ? n.copyWith(read: true) : n];
    state = AsyncData(next);
    await _persist(next);
  }

  Future<void> markAllRead() async {
    final items = state.valueOrNull;
    if (items == null) return;
    final next = [for (final n in items) n.copyWith(read: true)];
    state = AsyncData(next);
    await _persist(next);
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, List<AppNotification>>(NotificationsController.new);

final unreadNotificationsProvider = Provider<int>(
  (ref) => (ref.watch(notificationsProvider).valueOrNull ?? const []).where((n) => !n.read).length,
);
