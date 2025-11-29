import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/data/models/booking_history_entry_model.dart';
import '../models/global_booking_model.dart';
import '../models/parking_slot_model.dart';
import '../../core/services/encryption_service.dart';

class BookingRepository {
  final FirebaseFirestore _firestore;
  final EncryptionService _encryptionService = EncryptionService();

  // Initialize collections in constructor
  BookingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Getter for bookings collection - no late initialization
  CollectionReference<Map<String, dynamic>> get _bookingsCollection =>
      _firestore.collection('bookings');

  // Create a new booking
  Future<String> createBooking({
    required String userId,
    required String userName,
    required String userEmail,
    required GlobalBookingModel booking,
    required String mallName,
  }) async {
    try {
      debugPrint('🔵 Starting booking creation...');
      debugPrint('🔵 User ID: $userId');
      debugPrint('🔵 Mall ID: ${booking.mallId}');
      debugPrint('🔵 Slot ID: ${booking.slotId}');

      // Encrypt sensitive data
      final encryptedData = _encryptionService.encryptData({
        'userName': booking.userName,
        'uniqueId': booking.uniqueId,
        'carNumber': booking.carNumber,
      });

      final bookingWithEncryption = booking.copyWith(
        encryptedData: encryptedData,
      );

      final batch = _firestore.batch();

      // 1. Add to global bookings collection
      debugPrint('🔵 Step 1: Adding to global bookings...');
      final globalBookingRef = _bookingsCollection.doc(booking.bookingId);
      batch.set(globalBookingRef, {
        ...bookingWithEncryption.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Step 1 prepared: ${booking.bookingId}');

      // 2. Add to mall's activeBookings
      debugPrint('🔵 Step 2: Adding to mall activeBookings...');
      final mallBookingRef = _firestore
          .collection('malls')
          .doc(booking.mallId)
          .collection('activeBookings')
          .doc(booking.bookingId);
      batch.set(mallBookingRef, {
        ...bookingWithEncryption.toFirestore(),
        'status': 'reserved',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Step 2 prepared');

      // 3. Update slot status
      debugPrint('🔵 Step 3: Updating slot status...');
      final slotRef = _firestore
          .collection('malls')
          .doc(booking.mallId)
          .collection('slots')
          .doc(booking.slotId);
      batch.update(slotRef, {
        'status': 'reserved',
        'currentBookingId': booking.bookingId,
        'currentUserId': userId,
        'reservationEndTime': booking.reservationEndTime,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Step 3 prepared');

      // 4. Update mall counters
      debugPrint('🔵 Step 4: Updating mall counters...');
      final mallRef = _firestore.collection('malls').doc(booking.mallId);
      batch.update(mallRef, {
        'availableSlots': FieldValue.increment(-1),
        'reservedSlots': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Step 4 prepared');

      // 5. Add to user's parking history
      debugPrint('🔵 Step 5: Adding to user parking history...');
      final userHistoryRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('parkingHistory')
          .doc(booking.bookingId);
      batch.set(userHistoryRef, {
        ...bookingWithEncryption.toFirestore(),
        'status': 'reserved',
        'mallName': mallName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Step 5 prepared');

      // Commit batch
      debugPrint('🔵 Committing batch...');
      await batch.commit();
      debugPrint('✅ Booking created successfully: ${booking.bookingId}');

      return booking.bookingId;
    } catch (e, stackTrace) {
      debugPrint('❌ Error in createBooking: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get user's active bookings
  Stream<List<GlobalBookingModel>> getUserActiveBookings(String userId) {
    try {
      return _bookingsCollection
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['reserved', 'active'])
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => GlobalBookingModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getUserActiveBookings: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return Stream.value([]);
    }
  }

  // Get booking by ID
  Future<GlobalBookingModel?> getBookingById(String bookingId) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();
      if (!doc.exists) return null;
      return GlobalBookingModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting booking: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Update booking status
  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
    String? mallId,
    String? slotId,
    String? userId,
  }) async {
    try {
      debugPrint('🔵 Updating booking status to: $status');
      final batch = _firestore.batch();
      final bookingRef = _bookingsCollection.doc(bookingId);
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update global booking
      batch.update(bookingRef, updateData);

      // Update in mall's activeBookings if mallId is provided
      if (mallId != null) {
        final mallBookingRef = _firestore
            .collection('malls')
            .doc(mallId)
            .collection('activeBookings')
            .doc(bookingId);
        batch.update(mallBookingRef, updateData);

        // Update user's parking history
        if (userId != null) {
          final userHistoryRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('parkingHistory')
              .doc(bookingId);
          batch.update(userHistoryRef, updateData);
        }
      }

      // Update slot status if slotId is provided
      if (mallId != null && slotId != null) {
        final slotRef = _firestore
            .collection('malls')
            .doc(mallId)
            .collection('slots')
            .doc(slotId);

        final slotUpdate = <String, dynamic>{
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        if (status == 'cancelled' || status == 'completed') {
          // Both cancelled and completed should release the slot
          slotUpdate['status'] = 'available';
          slotUpdate['currentBookingId'] = null;
          slotUpdate['currentUserId'] = null;
          slotUpdate['reservationEndTime'] = null;
        } else if (status == 'active') {
          slotUpdate['status'] = 'occupied';
        } else {
          slotUpdate['status'] = status;
        }

        batch.update(slotRef, slotUpdate);

        // Update mall counters
        final mallRef = _firestore.collection('malls').doc(mallId);
        if (status == 'cancelled') {
          batch.update(mallRef, {
            'availableSlots': FieldValue.increment(1),
            'reservedSlots': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else if (status == 'completed') {
          // Completed means checkout from occupied
          batch.update(mallRef, {
            'availableSlots': FieldValue.increment(1),
            'occupiedSlots': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else if (status == 'active') {
          batch.update(mallRef, {
            'reservedSlots': FieldValue.increment(-1),
            'occupiedSlots': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      debugPrint('✅ Booking status updated successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error in updateBookingStatus: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get parking slot by ID
  Future<ParkingSlotModel?> getParkingSlot({
    required String mallId,
    required String slotId,
  }) async {
    try {
      final doc = await _firestore
          .collection('malls')
          .doc(mallId)
          .collection('slots')
          .doc(slotId)
          .get();

      if (!doc.exists) return null;
      return ParkingSlotModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting parking slot: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Check if a slot is available for booking
  Future<bool> isSlotAvailable({
    required String mallId,
    required String slotId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final slot = await getParkingSlot(mallId: mallId, slotId: slotId);
      if (slot == null || !slot.isAvailable) return false;

      // Check for existing reservations in the time range
      final bookings = await _firestore
          .collection('malls')
          .doc(mallId)
          .collection('activeBookings')
          .where('slotId', isEqualTo: slotId)
          .where('status', whereIn: ['reserved', 'active'])
          .get();

      // Filter bookings that overlap with the requested time range
      final overlappingBookings = bookings.docs.where((doc) {
        final data = doc.data();
        if (data['reservationEndTime'] == null ||
            data['reservationStartTime'] == null) {
          return false;
        }

        final existingStart = (data['reservationStartTime'] as Timestamp)
            .toDate();
        final existingEnd = (data['reservationEndTime'] as Timestamp).toDate();

        // Check if times overlap
        return existingEnd.isAfter(startTime) &&
            existingStart.isBefore(endTime);
      });

      return overlappingBookings.isEmpty;
    } catch (e, stackTrace) {
      debugPrint('❌ Error checking slot availability: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get active bookings for a mall
  Stream<List<GlobalBookingModel>> getActiveBookingsForMall(String mallId) {
    try {
      return _firestore
          .collection('malls')
          .doc(mallId)
          .collection('activeBookings')
          .where('status', whereIn: ['reserved', 'active'])
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => GlobalBookingModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getActiveBookingsForMall: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return Stream.value([]);
    }
  }

  // Complete booking (checkout)
  Future<void> completeBooking({
    required String bookingId,
    required String userId,
    required String mallId,
    required String slotId,
    required DateTime checkOutDateTime,
  }) async {
    try {
      debugPrint('🔵 Starting checkout for booking: $bookingId');

      // Get the booking to calculate duration
      final bookingDoc = await _bookingsCollection.doc(bookingId).get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data()!;
      final checkInDateTime = (bookingData['reservationStartTime'] as Timestamp)
          .toDate();
      final duration = _calculateDuration(checkInDateTime, checkOutDateTime);

      final batch = _firestore.batch();

      // 1. Update global booking
      debugPrint('🔵 Step 1: Updating global booking...');
      batch.update(_bookingsCollection.doc(bookingId), {
        'status': 'completed',
        'checkOutDateTime': Timestamp.fromDate(checkOutDateTime),
        'duration': duration,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Remove from mall's activeBookings and add to bookingHistory
      debugPrint('🔵 Step 2: Moving to booking history...');
      final mallActiveBookingRef = _firestore
          .collection('malls')
          .doc(mallId)
          .collection('activeBookings')
          .doc(bookingId);

      final activeBookingDoc = await mallActiveBookingRef.get();
      if (activeBookingDoc.exists) {
        final activeBookingData = activeBookingDoc.data()!;

        // Move to history
        batch.set(
          _firestore
              .collection('malls')
              .doc(mallId)
              .collection('bookingHistory')
              .doc(bookingId),
          {
            ...activeBookingData,
            'checkOutDateTime': Timestamp.fromDate(checkOutDateTime),
            'duration': duration,
            'status': 'completed',
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Delete from active
        batch.delete(mallActiveBookingRef);
      }

      // 3. Update user's parkingHistory
      debugPrint('🔵 Step 3: Updating user parking history...');
      batch.update(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('parkingHistory')
            .doc(bookingId),
        {
          'checkOutDateTime': Timestamp.fromDate(checkOutDateTime),
          'status': 'completed',
          'duration': duration,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // 4. Update slot status
      debugPrint('🔵 Step 4: Freeing slot...');
      batch.update(
        _firestore
            .collection('malls')
            .doc(mallId)
            .collection('slots')
            .doc(slotId),
        {
          'status': 'available',
          'currentBookingId': null,
          'currentUserId': null,
          'reservationEndTime': null,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
      );

      // 5. Update mall statistics
      debugPrint('🔵 Step 5: Updating mall statistics...');
      batch.update(_firestore.collection('malls').doc(mallId), {
        'availableSlots': FieldValue.increment(1),
        'occupiedSlots': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('🔵 Committing checkout batch...');
      await batch.commit();
      debugPrint('✅ Checkout completed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error completing booking: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Calculate duration
  String _calculateDuration(DateTime checkIn, DateTime checkOut) {
    final duration = checkOut.difference(checkIn);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} ${minutes > 0 ? '$minutes min${minutes > 1 ? 's' : ''}' : ''}';
    } else {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  // Cancel booking
  Future<void> cancelBooking({
    required String bookingId,
    required String userId,
    required String mallId,
    required String slotId,
  }) async {
    try {
      debugPrint('🔵 Cancelling booking: $bookingId');
      final batch = _firestore.batch();

      // Update global booking
      batch.update(_bookingsCollection.doc(bookingId), {
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove from mall's activeBookings
      batch.delete(
        _firestore
            .collection('malls')
            .doc(mallId)
            .collection('activeBookings')
            .doc(bookingId),
      );

      // Update user's parkingHistory
      batch.update(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('parkingHistory')
            .doc(bookingId),
        {'status': 'cancelled', 'updatedAt': FieldValue.serverTimestamp()},
      );

      // Update slot status
      batch.update(
        _firestore
            .collection('malls')
            .doc(mallId)
            .collection('slots')
            .doc(slotId),
        {
          'status': 'available',
          'currentBookingId': null,
          'currentUserId': null,
          'reservationEndTime': null,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
      );

      // Update mall statistics
      batch.update(_firestore.collection('malls').doc(mallId), {
        'availableSlots': FieldValue.increment(1),
        'reservedSlots': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      debugPrint('✅ Booking cancelled successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error cancelling booking: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  // In BookingRepository class
  Stream<List<BookingHistoryEntry>> getUserParkingHistory(String userId) {
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('parkingHistory')
          .orderBy('checkInDateTime', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => BookingHistoryEntry.fromFirestore(doc))
                .toList(),
          );
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getUserParkingHistory: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return Stream.value([]);
    }
  }

  // Decrypt booking data (admin only)
  Map<String, dynamic> decryptBookingData(String encryptedData) {
    try {
      return _encryptionService.decryptData(encryptedData);
    } catch (e) {
      debugPrint('❌ Error decrypting data: $e');
      rethrow;
    }
  }
}
