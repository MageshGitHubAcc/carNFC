import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveBookingModel {
  final String bookingId;
  final String userId;
  final String userName;
  final String userEmail;
  final String uniqueId;
  final String carNumber;
  final String carType;
  final String vehicleCategory;
  final String slotId;
  final int slotNumber;
  final DateTime checkInDateTime;
  final String status;
  final String encryptedData;
  final DateTime createdAt;

  ActiveBookingModel({
    required this.bookingId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.uniqueId,
    required this.carNumber,
    required this.carType,
    required this.vehicleCategory,
    required this.slotId,
    required this.slotNumber,
    required this.checkInDateTime,
    required this.status,
    required this.encryptedData,
    required this.createdAt,
  });

  factory ActiveBookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ActiveBookingModel(
      bookingId: doc.id,
      userId: data['userId'],
      userName: data['userName'],
      userEmail: data['userEmail'],
      uniqueId: data['uniqueId'],
      carNumber: data['carNumber'],
      carType: data['carType'],
      vehicleCategory: data['vehicleCategory'],
      slotId: data['slotId'],
      slotNumber: data['slotNumber'],
      checkInDateTime: (data['checkInDateTime'] as Timestamp).toDate(),
      status: data['status'],
      encryptedData: data['encryptedData'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'uniqueId': uniqueId,
      'carNumber': carNumber,
      'carType': carType,
      'vehicleCategory': vehicleCategory,
      'slotId': slotId,
      'slotNumber': slotNumber,
      'checkInDateTime': Timestamp.fromDate(checkInDateTime),
      'status': status,
      'encryptedData': encryptedData,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
