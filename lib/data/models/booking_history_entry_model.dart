// lib/data/models/booking_history_entry.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingHistoryEntry {
  final String bookingId;
  final String mallName;
  final String slotNumber;
  final DateTime checkInDateTime;
  final DateTime? checkOutDateTime;
  final String status;
  final String? duration;

  BookingHistoryEntry({
    required this.bookingId,
    required this.mallName,
    required this.slotNumber,
    required this.checkInDateTime,
    this.checkOutDateTime,
    required this.status,
    this.duration,
  });

  factory BookingHistoryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingHistoryEntry(
      bookingId: doc.id,
      mallName: data['mallName'] ?? 'Unknown Mall',
      slotNumber: data['slotNumber']?.toString() ?? 'N/A',
      checkInDateTime: (data['checkInDateTime'] as Timestamp).toDate(),
      checkOutDateTime: data['checkOutDateTime'] != null
          ? (data['checkOutDateTime'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'completed',
      duration: data['duration'],
    );
  }
}
