import 'package:cloud_firestore/cloud_firestore.dart';

class MallBookingHistoryEntry {
  MallBookingHistoryEntry({
    required this.bookingId,
    required this.userName,
    required this.carNumber,
    required this.slotNumber,
    required this.checkIn,
    required this.status,
    required this.mallId,
    this.checkOut,
    this.amount,
  });

  final String bookingId;
  final String userName;
  final String carNumber;
  final int slotNumber;
  final DateTime checkIn;
  final String status;
  final String mallId;
  final DateTime? checkOut;
  final num? amount;

  factory MallBookingHistoryEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String mallId,
  ) {
    final data = doc.data() ?? {};
    return MallBookingHistoryEntry(
      bookingId: doc.id,
      mallId: mallId,
      userName: data['userName'] ?? 'Unknown user',
      carNumber: data['carNumber'] ?? 'N/A',
      slotNumber: data['slotNumber'] ?? 0,
      status: data['status'] ?? 'completed',
      checkIn:
          (data['checkInDateTime'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      checkOut: (data['checkOutDateTime'] as Timestamp?)?.toDate(),
      amount: data['amount'],
    );
  }
}
