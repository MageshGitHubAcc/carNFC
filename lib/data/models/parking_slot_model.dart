import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingSlotModel {
  final String slotId;
  final int slotNumber;
  final String fuelType; // petrol | ev
  final String? categoryRestriction;
  final String status; // available | occupied | reserved | maintenance
  final String? floor;
  final String? zone;
  final String? currentBookingId;
  final String? currentUserId;
  final DateTime? reservationEndTime;
  final DateTime lastUpdated;

  bool get isAvailable => status == 'available';
  bool get isReserved => status == 'reserved';
  bool get isOccupied => status == 'occupied';
  bool isReservationExpired() {
    if (status != 'reserved' || reservationEndTime == null) return false;
    return DateTime.now().isAfter(
      reservationEndTime!.add(const Duration(minutes: 10)),
    ); // 10 mins grace period
  }

  ParkingSlotModel({
    required this.slotId,
    required this.slotNumber,
    required this.fuelType,
    this.categoryRestriction,
    required this.status,
    this.floor,
    this.zone,
    this.currentBookingId,
    this.currentUserId,
    this.reservationEndTime,
    required this.lastUpdated,
  });

  factory ParkingSlotModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      return ParkingSlotModel(
        slotId: doc.id,
        slotNumber: data['slotNumber'] ?? 0,
        fuelType: data['fuelType'] ?? 'petrol',
        categoryRestriction: data['categoryRestriction'],
        status: data['status'] ?? 'available',
        floor: data['floor'],
        zone: data['zone'],
        currentBookingId: data['currentBookingId'],
        currentUserId: data['currentUserId'],
        reservationEndTime: data['reservationEndTime'] != null
            ? (data['reservationEndTime'] as Timestamp).toDate()
            : null,
        lastUpdated: data['lastUpdated'] is Timestamp
            ? (data['lastUpdated'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } catch (e, stack) {
      print('Error parsing ParkingSlotModel for doc ${doc.id}: $e');
      print('Data: ${doc.data()}');
      print(stack);
      return ParkingSlotModel(
        slotId: doc.id,
        slotNumber: 0,
        fuelType: 'unknown',
        status: 'maintenance',
        lastUpdated: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'slotNumber': slotNumber,
      'fuelType': fuelType,
      'categoryRestriction': categoryRestriction,
      'status': status,
      'floor': floor,
      'zone': zone,
      'currentBookingId': currentBookingId,
      'currentUserId': currentUserId,
      'reservationEndTime': reservationEndTime != null
          ? Timestamp.fromDate(reservationEndTime!)
          : null,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
