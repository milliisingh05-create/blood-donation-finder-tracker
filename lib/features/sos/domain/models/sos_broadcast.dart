import 'package:cloud_firestore/cloud_firestore.dart';
import 'sos_responder.dart';

/// Model representing an active or completed high-priority SOS emergency broadcast.
class SosBroadcast {
  final String id;
  final String requestId;
  final double radiusKm;
  final DateTime createdAt;
  final String status; // 'broadcasting', 'resolved', 'cancelled'
  final int notifiedCount;
  final int acceptedCount;
  final String? bloodGroup;
  final String? hospitalName;
  final List<SosResponder> responders;
  final List<String> timelineLogs;

  const SosBroadcast({
    required this.id,
    required this.requestId,
    this.radiusKm = 5.0,
    required this.createdAt,
    this.status = 'broadcasting',
    this.notifiedCount = 0,
    this.acceptedCount = 0,
    this.bloodGroup,
    this.hospitalName,
    this.responders = const [],
    this.timelineLogs = const [],
  });

  bool get isBroadcasting => status.toLowerCase() == 'broadcasting';
  bool get isResolved => status.toLowerCase() == 'resolved';

  SosBroadcast copyWith({
    String? id,
    String? requestId,
    double? radiusKm,
    DateTime? createdAt,
    String? status,
    int? notifiedCount,
    int? acceptedCount,
    String? bloodGroup,
    String? hospitalName,
    List<SosResponder>? responders,
    List<String>? timelineLogs,
  }) {
    return SosBroadcast(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      radiusKm: radiusKm ?? this.radiusKm,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      notifiedCount: notifiedCount ?? this.notifiedCount,
      acceptedCount: acceptedCount ?? this.acceptedCount,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      hospitalName: hospitalName ?? this.hospitalName,
      responders: responders ?? this.responders,
      timelineLogs: timelineLogs ?? this.timelineLogs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestId': requestId,
      'radiusKm': radiusKm,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'notifiedCount': notifiedCount,
      'acceptedCount': acceptedCount,
      'bloodGroup': bloodGroup,
      'hospitalName': hospitalName,
      'responders': responders.map((r) => r.toMap()).toList(),
      'timelineLogs': timelineLogs,
    };
  }

  factory SosBroadcast.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final rawResponders = map['responders'];
    final List<SosResponder> parsedResponders = [];
    if (rawResponders is List) {
      for (final r in rawResponders) {
        if (r is Map<String, dynamic>) {
          parsedResponders.add(SosResponder.fromMap(r));
        }
      }
    }

    final rawLogs = map['timelineLogs'];
    final List<String> parsedLogs = [];
    if (rawLogs is List) {
      for (final l in rawLogs) {
        if (l != null) parsedLogs.add(l.toString());
      }
    }

    return SosBroadcast(
      id: documentId ?? map['id'] as String? ?? '',
      requestId: map['requestId'] as String? ?? '',
      radiusKm: (map['radiusKm'] as num?)?.toDouble() ?? 5.0,
      createdAt: parseDate(map['createdAt']),
      status: map['status'] as String? ?? 'broadcasting',
      notifiedCount: (map['notifiedCount'] as num?)?.toInt() ?? 0,
      acceptedCount: (map['acceptedCount'] as num?)?.toInt() ?? 0,
      bloodGroup: map['bloodGroup'] as String?,
      hospitalName: map['hospitalName'] as String?,
      responders: parsedResponders,
      timelineLogs: parsedLogs,
    );
  }
}
