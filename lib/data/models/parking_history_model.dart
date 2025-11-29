import 'package:cloud_firestore/cloud_firestore.dart';

enum ParkingStatus { active, completed, cancelled }

class ParkingHistoryModel {
  final String id;
  final String mallId;
  final String mallName;
  final String slotId;
  final int slotNumber;
  final String carNumber;
  final String carType;
  final String vehicleCategory;
  final DateTime checkInDateTime;
  final DateTime? checkOutDateTime;
  final ParkingStatus status;
  final String? duration;
  final DateTime createdAt;

  const ParkingHistoryModel({
    required this.id,
    required this.mallId,
    required this.mallName,
    required this.slotId,
    required this.slotNumber,
    required this.carNumber,
    required this.carType,
    required this.vehicleCategory,
    required this.checkInDateTime,
    this.checkOutDateTime,
    required this.status,
    this.duration,
    required this.createdAt,
  });

  /// Builds a [ParkingHistoryModel] from Firestore document snapshots.
  factory ParkingHistoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ParkingHistoryModel.fromMap(doc.data() ?? {}, docId: doc.id);
  }

  /// Builds a [ParkingHistoryModel] from raw map data.
  factory ParkingHistoryModel.fromMap(
    Map<String, dynamic> data, {
    String? docId,
  }) {
    return ParkingHistoryModel(
      id: docId ?? data['id'] as String? ?? '',
      mallId: data['mallId'] as String? ?? '',
      mallName: data['mallName'] as String? ?? '',
      slotId: data['slotId'] as String? ?? '',
      slotNumber: (data['slotNumber'] as num?)?.toInt() ?? 0,
      carNumber: data['carNumber'] as String? ?? '',
      carType: data['carType'] as String? ?? '',
      vehicleCategory: data['vehicleCategory'] as String? ?? '',
      checkInDateTime: _toDateTime(data['checkInDateTime']) ?? DateTime.now(),
      checkOutDateTime: _toDateTime(data['checkOutDateTime']),
      status: _statusFromString(data['status']),
      duration: data['duration'] as String?,
      createdAt: _toDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mallId': mallId,
      'mallName': mallName,
      'slotId': slotId,
      'slotNumber': slotNumber,
      'carNumber': carNumber,
      'carType': carType,
      'vehicleCategory': vehicleCategory,
      'checkInDateTime': Timestamp.fromDate(checkInDateTime),
      'checkOutDateTime': checkOutDateTime != null
          ? Timestamp.fromDate(checkOutDateTime!)
          : null,
      'status': status.name,
      'duration': duration,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mallId': mallId,
      'mallName': mallName,
      'slotId': slotId,
      'slotNumber': slotNumber,
      'carNumber': carNumber,
      'carType': carType,
      'vehicleCategory': vehicleCategory,
      'checkInDateTime': checkInDateTime.toIso8601String(),
      'checkOutDateTime': checkOutDateTime?.toIso8601String(),
      'status': status.name,
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ParkingHistoryModel copyWith({
    String? id,
    String? mallId,
    String? mallName,
    String? slotId,
    int? slotNumber,
    String? carNumber,
    String? carType,
    String? vehicleCategory,
    DateTime? checkInDateTime,
    DateTime? checkOutDateTime,
    ParkingStatus? status,
    String? duration,
    DateTime? createdAt,
  }) {
    return ParkingHistoryModel(
      id: id ?? this.id,
      mallId: mallId ?? this.mallId,
      mallName: mallName ?? this.mallName,
      slotId: slotId ?? this.slotId,
      slotNumber: slotNumber ?? this.slotNumber,
      carNumber: carNumber ?? this.carNumber,
      carType: carType ?? this.carType,
      vehicleCategory: vehicleCategory ?? this.vehicleCategory,
      checkInDateTime: checkInDateTime ?? this.checkInDateTime,
      checkOutDateTime: checkOutDateTime ?? this.checkOutDateTime,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Returns a sample entry using the provided dummy values.
  factory ParkingHistoryModel.dummy() {
    final checkIn = DateTime.now().subtract(const Duration(hours: 3));
    return ParkingHistoryModel(
      id: 'sample_booking',
      mallId: 'mall_a',
      mallName: 'ABC Mall',
      slotId: 'slot_123',
      slotNumber: 15,
      carNumber: 'KA01AB1234',
      carType: 'Honda City',
      vehicleCategory: 'sedan',
      checkInDateTime: checkIn,
      checkOutDateTime: checkIn.add(const Duration(hours: 2, minutes: 30)),
      status: ParkingStatus.completed,
      duration: '2 hours 30 mins',
      createdAt: checkIn,
    );
  }
}

ParkingStatus _statusFromString(dynamic value) {
  if (value is ParkingStatus) return value;
  final stringValue = value?.toString();
  return ParkingStatus.values.firstWhere(
    (status) => status.name == stringValue,
    orElse: () => ParkingStatus.active,
  );
}

DateTime? _toDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
