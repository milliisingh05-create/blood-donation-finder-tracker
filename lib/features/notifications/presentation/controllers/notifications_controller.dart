import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notifications_repository.dart';
import '../../domain/models/app_notification.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository();
});

final notificationsStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.watchNotifications('current_user');
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifsAsync = ref.watch(notificationsStreamProvider);
  return notifsAsync.maybeWhen(
    data: (list) => list.where((n) => !n.read).length,
    orElse: () => 0,
  );
});
