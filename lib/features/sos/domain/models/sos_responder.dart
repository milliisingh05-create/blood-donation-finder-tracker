/// Model representing a responder to an Emergency SOS broadcast.
class SosResponder {
  final String id;
  final String name;
  final String phone;
  final String bloodGroup;
  final double distanceKm;
  final int etaMinutes;
  final String status; // 'en_route', 'arrived', 'drawing', 'completed'
  final String transportMode; // 'Vehicle', 'Bicycle', 'Walking'
  final DateTime respondedAt;

  const SosResponder({
    required this.id,
    required this.name,
    required this.phone,
    required this.bloodGroup,
    required this.distanceKm,
    required this.etaMinutes,
    this.status = 'en_route',
    this.transportMode = 'Vehicle',
    required this.respondedAt,
  });

  bool get isEnRoute => status == 'en_route';
  bool get hasArrived => status == 'arrived';
  bool get isDrawing => status == 'drawing';
  bool get isCompleted => status == 'completed';

  String get formattedStatus {
    switch (status) {
      case 'arrived':
        return 'Arrived at Reception';
      case 'drawing':
        return 'Blood Draw in Progress';
      case 'completed':
        return 'Donation Completed';
      case 'en_route':
      default:
        return 'En Route ($etaMinutes min ETA)';
    }
  }

  SosResponder copyWith({
    String? id,
    String? name,
    String? phone,
    String? bloodGroup,
    double? distanceKm,
    int? etaMinutes,
    String? status,
    String? transportMode,
    DateTime? respondedAt,
  }) {
    return SosResponder(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      distanceKm: distanceKm ?? this.distanceKm,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      status: status ?? this.status,
      transportMode: transportMode ?? this.transportMode,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'distanceKm': distanceKm,
      'etaMinutes': etaMinutes,
      'status': status,
      'transportMode': transportMode,
      'respondedAt': respondedAt.toIso8601String(),
    };
  }

  factory SosResponder.fromMap(Map<String, dynamic> map) {
    return SosResponder(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      bloodGroup: map['bloodGroup'] as String? ?? 'O+',
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 2.0,
      etaMinutes: (map['etaMinutes'] as num?)?.toInt() ?? 10,
      status: map['status'] as String? ?? 'en_route',
      transportMode: map['transportMode'] as String? ?? 'Vehicle',
      respondedAt: DateTime.tryParse(map['respondedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
