import 'package:cloud_firestore/cloud_firestore.dart';

class BookingHistoryModel {
  final String bookingId;
  final String userId;
  final String userName;
  final String carNumber;
  final int slotNumber;
  final DateTime checkInDateTime;
  final DateTime checkOutDateTime;
  final String duration;
  final String status;
  final DateTime createdAt;

  BookingHistoryModel({
    required this.bookingId,
    required this.userId,
    required this.userName,
    required this.carNumber,
    required this.slotNumber,
    required this.checkInDateTime,
    required this.checkOutDateTime,
    required this.duration,
    required this.status,
    required this.createdAt,
  });

  factory BookingHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BookingHistoryModel(
      bookingId: doc.id,
      userId: data['userId'],
      userName: data['userName'],
      carNumber: data['carNumber'],
      slotNumber: data['slotNumber'],
      checkInDateTime: (data['checkInDateTime'] as Timestamp).toDate(),
      checkOutDateTime: (data['checkOutDateTime'] as Timestamp).toDate(),
      duration: data['duration'],
      status: data['status'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'carNumber': carNumber,
      'slotNumber': slotNumber,
      'checkInDateTime': Timestamp.fromDate(checkInDateTime),
      'checkOutDateTime': Timestamp.fromDate(checkOutDateTime),
      'duration': duration,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
