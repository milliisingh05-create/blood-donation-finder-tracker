import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/config/app_config.dart';

/// User profile model for blood donors, recipients, and general users.
class UserProfile {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String bloodGroup;
  final String gender;
  final DateTime? dob;
  final double? weight;
  final String city;
  final String geohash;
  final double latitude;
  final double longitude;
  final bool isDonor;
  final String role; // 'donor', 'recipient', 'staff', 'admin', 'hospital'
  final String availability; // 'active' or 'inactive'
  final DateTime? lastDonationDate;
  final int points;
  final List<String> badges;
  final String? fcmToken;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.bloodGroup,
    this.gender = 'unspecified',
    this.dob,
    this.weight,
    required this.city,
    required this.geohash,
    required this.latitude,
    required this.longitude,
    this.isDonor = true,
    this.role = 'donor',
    this.availability = 'active',
    this.lastDonationDate,
    this.points = 0,
    this.badges = const [],
    this.fcmToken,
    required this.createdAt,
  });

  bool get isActive => availability.toLowerCase() == 'active';
  bool get isStaffOrAdmin => role == 'staff' || role == 'admin' || role == 'hospital';

  /// Whether the donor is medically eligible to donate (90 days since last donation)
  bool get isEligible {
    if (lastDonationDate == null) return true;
    final diff = DateTime.now().difference(lastDonationDate!).inDays;
    return diff >= AppConfig.eligibilityDays;
  }

  /// Number of days remaining until eligible
  int get daysUntilEligible {
    if (lastDonationDate == null) return 0;
    final diff = DateTime.now().difference(lastDonationDate!).inDays;
    final remaining = AppConfig.eligibilityDays - diff;
    return remaining > 0 ? remaining : 0;
  }

  /// Privacy helper: masks phone number when browsing public donor list
  String get maskedPhone {
    if (phone.length <= 4) return '***';
    final start = phone.substring(0, 3);
    final end = phone.substring(phone.length - 2);
    return '$start-***-**$end';
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? phone,
    String? email,
    String? bloodGroup,
    String? gender,
    DateTime? dob,
    double? weight,
    String? city,
    String? geohash,
    double? latitude,
    double? longitude,
    bool? isDonor,
    String? role,
    String? availability,
    DateTime? lastDonationDate,
    int? points,
    List<String>? badges,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      weight: weight ?? this.weight,
      city: city ?? this.city,
      geohash: geohash ?? this.geohash,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDonor: isDonor ?? this.isDonor,
      role: role ?? this.role,
      availability: availability ?? this.availability,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      points: points ?? this.points,
      badges: badges ?? this.badges,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'bloodGroup': bloodGroup,
      'gender': gender,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'weight': weight,
      'city': city,
      'geohash': geohash,
      'location': GeoPoint(latitude, longitude),
      'isDonor': isDonor,
      'role': role,
      'availability': availability,
      'lastDonationDate': lastDonationDate != null ? Timestamp.fromDate(lastDonationDate!) : null,
      'points': points,
      'badges': badges,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final location = map['location'] as GeoPoint?;

    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return UserProfile(
      uid: documentId ?? map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      bloodGroup: map['bloodGroup'] as String? ?? 'O+',
      gender: map['gender'] as String? ?? 'unspecified',
      dob: parseDate(map['dob']),
      weight: (map['weight'] as num?)?.toDouble(),
      city: map['city'] as String? ?? '',
      geohash: map['geohash'] as String? ?? '',
      latitude: location?.latitude ?? (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: location?.longitude ?? (map['longitude'] as num?)?.toDouble() ?? 0.0,
      isDonor: map['isDonor'] as bool? ?? true,
      role: map['role'] as String? ?? 'donor',
      availability: map['availability'] as String? ?? 'active',
      lastDonationDate: parseDate(map['lastDonationDate']),
      points: (map['points'] as num?)?.toInt() ?? 0,
      badges: List<String>.from(map['badges'] as List? ?? []),
      fcmToken: map['fcmToken'] as String?,
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }
}
