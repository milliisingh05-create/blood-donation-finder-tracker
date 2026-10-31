import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification entity for in-app alert inbox and push message payload.
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'sos', 'request', 'acceptance', 'reminder', 'system'
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.read = false,
    required this.createdAt,
    this.data,
  });

  bool get isSos => type.toLowerCase() == 'sos';
  bool get isRequest => type.toLowerCase() == 'request';
  bool get isAcceptance => type.toLowerCase() == 'acceptance';

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    bool? read,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
      'data': data,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return AppNotification(
      id: documentId ?? map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'system',
      read: map['read'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
      data: map['data'] != null ? Map<String, dynamic>.from(map['data'] as Map) : null,
    );
  }
}
