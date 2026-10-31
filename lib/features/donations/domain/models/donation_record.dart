import 'package:cloud_firestore/cloud_firestore.dart';

/// Completed blood donation record model.
class DonationRecord {
  final String id;
  final String donorId;
  final String? donorName;
  final String? requestId;
  final String hospitalId;
  final String hospitalName;
  final String bloodGroup;
  final String donationType;
  final int units;
  final DateTime date;
  final bool verified;
  final int pointsEarned;

  const DonationRecord({
    required this.id,
    required this.donorId,
    this.donorName,
    this.requestId,
    required this.hospitalId,
    required this.hospitalName,
    required this.bloodGroup,
    this.donationType = 'Whole Blood',
    this.units = 1,
    required this.date,
    this.verified = true,
    this.pointsEarned = 100,
  });

  DonationRecord copyWith({
    String? id,
    String? donorId,
    String? donorName,
    String? requestId,
    String? hospitalId,
    String? hospitalName,
    String? bloodGroup,
    String? donationType,
    int? units,
    DateTime? date,
    bool? verified,
    int? pointsEarned,
  }) {
    return DonationRecord(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      requestId: requestId ?? this.requestId,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      donationType: donationType ?? this.donationType,
      units: units ?? this.units,
      date: date ?? this.date,
      verified: verified ?? this.verified,
      pointsEarned: pointsEarned ?? this.pointsEarned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donorId': donorId,
      'donorName': donorName,
      'requestId': requestId,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'bloodGroup': bloodGroup,
      'donationType': donationType,
      'units': units,
      'date': Timestamp.fromDate(date),
      'verified': verified,
      'pointsEarned': pointsEarned,
    };
  }

  factory DonationRecord.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return DonationRecord(
      id: documentId ?? map['id'] as String? ?? '',
      donorId: map['donorId'] as String? ?? '',
      donorName: map['donorName'] as String?,
      requestId: map['requestId'] as String?,
      hospitalId: map['hospitalId'] as String? ?? '',
      hospitalName: map['hospitalName'] as String? ?? 'General Medical Center',
      bloodGroup: map['bloodGroup'] as String? ?? 'O+',
      donationType: map['donationType'] as String? ?? 'Whole Blood',
      units: (map['units'] as num?)?.toInt() ?? 1,
      date: parseDate(map['date']),
      verified: map['verified'] as bool? ?? true,
      pointsEarned: (map['pointsEarned'] as num?)?.toInt() ?? 100,
    );
  }
}
