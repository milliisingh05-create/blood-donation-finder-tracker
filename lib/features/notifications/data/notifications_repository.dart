import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../domain/models/app_notification.dart';

/// Repository managing in-app push alerts and notification history.
class NotificationsRepository {
  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  // In-memory notifications for development & offline testing
  final List<AppNotification> _demoNotifications = [
    AppNotification(
      id: 'notif_001',
      userId: 'current_user',
      title: '🚨 Critical O- Blood Needed!',
      body: 'Metro General Hospital ICU needs 2 units of O- blood urgently for an emergency trauma patient.',
      type: 'sos',
      read: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      data: {'requestId': 'req_001', 'urgency': 'critical'},
    ),
    AppNotification(
      id: 'notif_002',
      userId: 'current_user',
      title: '✅ Request Accepted',
      body: 'Elena Rostova (O-) has accepted your blood request. Contact details are now available.',
      type: 'acceptance',
      read: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      data: {'requestId': 'req_001', 'donorId': 'donor_001'},
    ),
    AppNotification(
      id: 'notif_003',
      userId: 'current_user',
      title: '🩸 Donation Eligibility Update',
      body: 'You are now eligible to donate blood again! Your previous donation was over 90 days ago.',
      type: 'reminder',
      read: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AppNotification(
      id: 'notif_004',
      userId: 'current_user',
      title: '🏆 New Badge Earned!',
      body: 'Congratulations! You earned the "Community Hero" badge for responding to 3 requests.',
      type: 'system',
      read: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  final _controller = StreamController<List<AppNotification>>.broadcast();

  NotificationsRepository() {
    _emit();
  }

  void _emit() {
    _controller.add(List.unmodifiable(_demoNotifications));
  }

  /// Watch notifications for the current user
  Stream<List<AppNotification>> watchNotifications(String userId) async* {
    yield List.unmodifiable(_demoNotifications);

    if (!_isFirebaseReady) {
      yield* _controller.stream;
    } else {
      yield* FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.data(), documentId: doc.id))
            .toList();
      });
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId, {String? userId}) async {
    final idx = _demoNotifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _demoNotifications[idx] = _demoNotifications[idx].copyWith(read: true);
      _emit();
    }

    if (!_isFirebaseReady || userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (_) {}
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead({String? userId}) async {
    for (int i = 0; i < _demoNotifications.length; i++) {
      _demoNotifications[i] = _demoNotifications[i].copyWith(read: true);
    }
    _emit();

    if (!_isFirebaseReady || userId == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final docs = await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      for (final doc in docs.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Add a new notification
  Future<void> addNotification(AppNotification notif) async {
    _demoNotifications.insert(0, notif);
    _emit();

    if (!_isFirebaseReady) return;

    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(notif.userId)
          .collection('notifications')
          .doc(notif.id)
          .set(notif.toMap());
    } catch (_) {}
  }

  void dispose() {
    _controller.close();
  }
}
