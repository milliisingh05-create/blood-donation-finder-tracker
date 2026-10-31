import 'package:cloud_firestore/cloud_firestore.dart';

/// Hospital and Blood Bank inventory model.
class Hospital {
  final String id;
  final String name;
  final String type; // 'hospital' or 'blood_bank'
  final String address;
  final double latitude;
  final double longitude;
  final String geohash;
  final String phone;
  final Map<String, int> bloodStock; // e.g. {'A+': 12, 'O-': 4}
  final DateTime updatedAt;

  const Hospital({
    required this.id,
    required this.name,
    this.type = 'hospital',
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.phone,
    this.bloodStock = const {},
    required this.updatedAt,
  });

  bool get isBloodBank => type.toLowerCase() == 'blood_bank';

  int stockFor(String bloodGroup) {
    return bloodStock[bloodGroup.toUpperCase()] ?? 0;
  }

  int get totalStockUnits {
    return bloodStock.values.fold(0, (total, units) => total + units);
  }

  Hospital copyWith({
    String? id,
    String? name,
    String? type,
    String? address,
    double? latitude,
    double? longitude,
    String? geohash,
    String? phone,
    Map<String, int>? bloodStock,
    DateTime? updatedAt,
  }) {
    return Hospital(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geohash: geohash ?? this.geohash,
      phone: phone ?? this.phone,
      bloodStock: bloodStock ?? this.bloodStock,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'location': GeoPoint(latitude, longitude),
      'geohash': geohash,
      'phone': phone,
      'bloodStock': bloodStock,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Hospital.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final location = map['location'] as GeoPoint?;

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final rawStock = map['bloodStock'];
    final Map<String, int> parsedStock = {};
    if (rawStock is Map) {
      rawStock.forEach((key, value) {
        if (value is num) {
          parsedStock[key.toString()] = value.toInt();
        }
      });
    }

    return Hospital(
      id: documentId ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'hospital',
      address: map['address'] as String? ?? '',
      latitude: location?.latitude ?? (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: location?.longitude ?? (map['longitude'] as num?)?.toDouble() ?? 0.0,
      geohash: map['geohash'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      bloodStock: parsedStock,
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
