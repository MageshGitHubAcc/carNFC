import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { active, completed, cancelled, reserved }

class GlobalBookingModel {
  final String bookingId;
  final String userId;
  final String userName;
  final String mallId;
  final String mallName;
  final String uniqueId;
  final String slotId;
  final int slotNumber;
  final String carNumber;
  final String carType;
  final String vehicleCategory;
  final DateTime checkInDateTime;
  final DateTime? checkOutDateTime;
  final BookingStatus status;
  final String? duration;
  final String encryptedData;
  final DateTime createdAt;
  final DateTime? reservationStartTime;
  final DateTime? reservationEndTime;

  GlobalBookingModel({
    required this.bookingId,
    required this.userId,
    required this.userName,
    required this.mallId,
    required this.mallName,
    required this.uniqueId,
    required this.slotId,
    required this.slotNumber,
    required this.carNumber,
    required this.carType,
    required this.vehicleCategory,
    required this.checkInDateTime,
    this.checkOutDateTime,
    required this.status,
    this.duration,
    required this.encryptedData,
    required this.createdAt,
    this.reservationStartTime,
    this.reservationEndTime,
  });

  GlobalBookingModel copyWith({
    String? bookingId,
    String? userId,
    String? userName,
    String? mallId,
    String? mallName,
    String? uniqueId,
    String? slotId,
    int? slotNumber,
    String? carNumber,
    String? carType,
    String? vehicleCategory,
    DateTime? checkInDateTime,
    DateTime? checkOutDateTime,
    BookingStatus? status,
    String? duration,
    String? encryptedData,
    DateTime? createdAt,
    DateTime? reservationStartTime,
    DateTime? reservationEndTime,
  }) {
    return GlobalBookingModel(
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      mallId: mallId ?? this.mallId,
      mallName: mallName ?? this.mallName,
      uniqueId: uniqueId ?? this.uniqueId,
      slotId: slotId ?? this.slotId,
      slotNumber: slotNumber ?? this.slotNumber,
      carNumber: carNumber ?? this.carNumber,
      carType: carType ?? this.carType,
      vehicleCategory: vehicleCategory ?? this.vehicleCategory,
      checkInDateTime: checkInDateTime ?? this.checkInDateTime,
      checkOutDateTime: checkOutDateTime ?? this.checkOutDateTime,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      encryptedData: encryptedData ?? this.encryptedData,
      createdAt: createdAt ?? this.createdAt,
      reservationStartTime: reservationStartTime ?? this.reservationStartTime,
      reservationEndTime: reservationEndTime ?? this.reservationEndTime,
    );
  }

  factory GlobalBookingModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final statusString =
          (data['status'] as String?) ?? BookingStatus.active.name;

      return GlobalBookingModel(
        bookingId: doc.id,
        userId: data['userId'] ?? '',
        userName: data['userName'] ?? 'Unknown User',
        mallId: data['mallId'] ?? '',
        mallName: data['mallName'] ?? 'Unknown Mall',
        uniqueId: data['uniqueId'] ?? '',
        slotId: data['slotId'] ?? '',
        slotNumber: data['slotNumber'] ?? 0,
        carNumber: data['carNumber'] ?? 'Unknown',
        carType: data['carType'] ?? 'Unknown',
        vehicleCategory: data['vehicleCategory'] ?? 'Unknown',
        checkInDateTime: data['checkInDateTime'] != null
            ? (data['checkInDateTime'] as Timestamp).toDate()
            : DateTime.now(),
        checkOutDateTime: data['checkOutDateTime'] != null
            ? (data['checkOutDateTime'] as Timestamp).toDate()
            : null,
        status: BookingStatus.values.firstWhere(
          (status) => status.name == statusString,
          orElse: () => BookingStatus.active,
        ),
        duration: data['duration'],
        encryptedData: data['encryptedData'] ?? '',
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        reservationStartTime: data['reservationStartTime'] != null
            ? (data['reservationStartTime'] as Timestamp).toDate()
            : null,
        reservationEndTime: data['reservationEndTime'] != null
            ? (data['reservationEndTime'] as Timestamp).toDate()
            : null,
      );
    } catch (e, stack) {
      print('Error parsing GlobalBookingModel for doc ${doc.id}: $e');
      print('Data: ${doc.data()}');
      print(stack);
      return GlobalBookingModel(
        bookingId: doc.id,
        userId: 'error',
        userName: 'Error',
        mallId: 'error',
        mallName: 'Error',
        uniqueId: 'error',
        slotId: 'error',
        slotNumber: 0,
        carNumber: 'ERROR',
        carType: 'Error',
        vehicleCategory: 'Error',
        checkInDateTime: DateTime.now(),
        status: BookingStatus.cancelled,
        encryptedData: '',
        createdAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'mallId': mallId,
      'mallName': mallName,
      'uniqueId': uniqueId,
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
      'encryptedData': encryptedData,
      'createdAt': Timestamp.fromDate(createdAt),
      'reservationStartTime': reservationStartTime != null
          ? Timestamp.fromDate(reservationStartTime!)
          : null,
      'reservationEndTime': reservationEndTime != null
          ? Timestamp.fromDate(reservationEndTime!)
          : null,
    };
  }
}
