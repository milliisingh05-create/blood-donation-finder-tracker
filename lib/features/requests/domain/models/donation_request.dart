import 'package:cloud_firestore/cloud_firestore.dart';

/// Blood donation request model.
class DonationRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String bloodGroup;
  final int units;
  final String urgency; // 'normal' or 'critical'
  final String hospitalId;
  final String hospitalName;
  final double latitude;
  final double longitude;
  final String geohash;
  final String contactNumber;
  final String note;
  final String status; // 'open', 'accepted', 'fulfilled', 'cancelled'
  final List<String> acceptedBy;
  final DateTime createdAt;

  const DonationRequest({
    required this.id,
    required this.requesterId,
    this.requesterName = 'Emergency Patient',
    required this.bloodGroup,
    this.units = 1,
    this.urgency = 'normal',
    this.hospitalId = '',
    required this.hospitalName,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.contactNumber,
    this.note = '',
    this.status = 'open',
    this.acceptedBy = const [],
    required this.createdAt,
  });

  bool get isCritical => urgency.toLowerCase() == 'critical';
  bool get isOpen => status.toLowerCase() == 'open';
  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isFulfilled => status.toLowerCase() == 'fulfilled';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  DonationRequest copyWith({
    String? id,
    String? requesterId,
    String? requesterName,
    String? bloodGroup,
    int? units,
    String? urgency,
    String? hospitalId,
    String? hospitalName,
    double? latitude,
    double? longitude,
    String? geohash,
    String? contactNumber,
    String? note,
    String? status,
    List<String>? acceptedBy,
    DateTime? createdAt,
  }) {
    return DonationRequest(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      units: units ?? this.units,
      urgency: urgency ?? this.urgency,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geohash: geohash ?? this.geohash,
      contactNumber: contactNumber ?? this.contactNumber,
      note: note ?? this.note,
      status: status ?? this.status,
      acceptedBy: acceptedBy ?? this.acceptedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'bloodGroup': bloodGroup,
      'units': units,
      'urgency': urgency,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'location': GeoPoint(latitude, longitude),
      'geohash': geohash,
      'contactNumber': contactNumber,
      'note': note,
      'status': status,
      'acceptedBy': acceptedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory DonationRequest.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final location = map['location'] as GeoPoint?;

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return DonationRequest(
      id: documentId ?? map['id'] as String? ?? '',
      requesterId: map['requesterId'] as String? ?? '',
      requesterName: map['requesterName'] as String? ?? 'Patient in Need',
      bloodGroup: map['bloodGroup'] as String? ?? 'O+',
      units: (map['units'] as num?)?.toInt() ?? 1,
      urgency: map['urgency'] as String? ?? 'normal',
      hospitalId: map['hospitalId'] as String? ?? '',
      hospitalName: map['hospitalName'] as String? ?? 'General Hospital',
      latitude: location?.latitude ?? (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: location?.longitude ?? (map['longitude'] as num?)?.toDouble() ?? 0.0,
      geohash: map['geohash'] as String? ?? '',
      contactNumber: map['contactNumber'] as String? ?? '',
      note: map['note'] as String? ?? '',
      status: map['status'] as String? ?? 'open',
      acceptedBy: List<String>.from(map['acceptedBy'] as List? ?? []),
      createdAt: parseDate(map['createdAt']),
    );
  }
}
