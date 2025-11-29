import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mall_booking_history_entry.dart';
import '../models/mall_model.dart';
import '../models/parking_slot_model.dart';

class MallRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all active malls
  // Get all malls (optionally include inactive ones)
  Stream<List<MallModel>> getMalls({bool includeInactive = false}) {
    Query query = _firestore.collection('malls');

    if (!includeInactive) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => MallModel.fromFirestore(doc)).toList(),
    );
  }

  // Deprecated: Use getMalls() instead
  Stream<List<MallModel>> getAllMalls() => getMalls(includeInactive: false);

  // Update slot metadata/status
  Future<void> updateSlot(
    String mallId,
    String slotId,
    Map<String, dynamic> updates,
  ) async {
    final payload = {...updates, 'lastUpdated': FieldValue.serverTimestamp()};

    final nestedRef = _firestore
        .collection('malls')
        .doc(mallId)
        .collection('slots')
        .doc(slotId);
    final nestedDoc = await nestedRef.get();
    if (nestedDoc.exists) {
      await nestedRef.update(payload);
      return;
    }

    final globalRef = _firestore.collection('slots').doc(slotId);
    final globalDoc = await globalRef.get();
    if (globalDoc.exists) {
      await globalRef.update(payload);
      return;
    }

    throw Exception('Slot $slotId not found for mall $mallId');
  }

  Stream<List<MallBookingHistoryEntry>> streamMallBookingHistory(
    String mallId,
  ) {
    return _firestore
        .collection('malls')
        .doc(mallId)
        .collection('bookingHistory')
        .orderBy('checkInDateTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MallBookingHistoryEntry.fromFirestore(doc, mallId))
              .toList(),
        );
  }

  // Get specific mall
  Future<MallModel?> getMallById(String mallId) async {
    final doc = await _firestore.collection('malls').doc(mallId).get();
    if (doc.exists) {
      return MallModel.fromFirestore(doc);
    }
    return null;
  }

  // Stream specific mall data
  Stream<MallModel?> streamMallData(String mallId) {
    return _firestore
        .collection('malls')
        .doc(mallId)
        .snapshots()
        .map((doc) => doc.exists ? MallModel.fromFirestore(doc) : null);
  }

  // Create a new mall (admin only)
  Future<String> createMall(MallModel mall) async {
    final docRef = await _firestore.collection('malls').add(mall.toFirestore());
    return docRef.id;
  }

  // Update mall (admin only)
  Future<void> updateMall(String mallId, Map<String, dynamic> updates) async {
    await _firestore.collection('malls').doc(mallId).update(updates);
  }

  // Stream slots for a mall (supports both nested and global slot collections)
  Stream<List<ParkingSlotModel>> streamMallSlots(String mallId) async* {
    final nestedSlotsRef = _firestore
        .collection('malls')
        .doc(mallId)
        .collection('slots');

    final nestedSnapshot = await nestedSlotsRef.limit(1).get();

    Query<Map<String, dynamic>> query;
    if (nestedSnapshot.docs.isNotEmpty) {
      query = nestedSlotsRef.orderBy('slotNumber');
    } else {
      query = _firestore
          .collection('slots')
          .where('mallId', isEqualTo: mallId)
          .orderBy('slotNumber');
    }

    yield* query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => ParkingSlotModel.fromFirestore(doc))
          .toList(),
    );
  }

  // Initialize slots for a mall (admin only - one time setup)
  Future<void> initializeSlots({
    required String mallId,
    required int totalSlots,
    required int petrolSlots,
    required int evSlots,
  }) async {
    final batch = _firestore.batch();

    for (int i = 1; i <= totalSlots; i++) {
      final slotRef = _firestore
          .collection('malls')
          .doc(mallId)
          .collection('slots')
          .doc();

      final slotData = {
        'slotNumber': i,
        'fuelType': i <= petrolSlots ? 'petrol' : 'ev',
        'categoryRestriction': null,
        'status': 'available',
        'floor': _determineFloor(i),
        'zone': _determineZone(i),
        'currentBookingId': null,
        'currentUserId': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      batch.set(slotRef, slotData);
    }

    // Update mall with available slots count
    batch.update(_firestore.collection('malls').doc(mallId), {
      'availableSlots': totalSlots,
      'occupiedSlots': 0,
    });

    await batch.commit();
  }

  // Helper: Determine floor (example logic)
  String _determineFloor(int slotNumber) {
    if (slotNumber <= 30) return 'B2';
    if (slotNumber <= 60) return 'B1';
    return 'Ground';
  }

  // Helper: Determine zone (example logic)
  String _determineZone(int slotNumber) {
    if (slotNumber % 3 == 0) return 'A';
    if (slotNumber % 3 == 1) return 'B';
    return 'C';
  }

  // Delete a mall and all associated data
  Future<void> deleteMall(String mallId) async {
    final batch = _firestore.batch();

    // Delete mall document
    batch.delete(_firestore.collection('malls').doc(mallId));

    // Delete all slots for this mall
    final slotsSnapshot = await _firestore
        .collection('slots')
        .where('mallId', isEqualTo: mallId)
        .get();
    for (var doc in slotsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete nested slots
    final nestedSlotsSnapshot = await _firestore
        .collection('malls')
        .doc(mallId)
        .collection('slots')
        .get();
    for (var doc in nestedSlotsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete active bookings from subcollection
    final activeBookingsSnapshot = await _firestore
        .collection('malls')
        .doc(mallId)
        .collection('activeBookings')
        .get();
    for (var doc in activeBookingsSnapshot.docs) {
      batch.delete(doc.reference);
      // Also delete from global bookings collection
      batch.delete(_firestore.collection('bookings').doc(doc.id));
    }

    // Delete booking history from subcollection
    final historySnapshot = await _firestore
        .collection('malls')
        .doc(mallId)
        .collection('bookingHistory')
        .get();
    for (var doc in historySnapshot.docs) {
      batch.delete(doc.reference);
      // Also delete from global bookings collection
      batch.delete(_firestore.collection('bookings').doc(doc.id));
    }

    // Delete bookings from global collection by mallId
    final globalBookingsSnapshot = await _firestore
        .collection('bookings')
        .where('mallId', isEqualTo: mallId)
        .get();
    for (var doc in globalBookingsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Delete all malls (admin only)
  Future<void> deleteAllMalls() async {
    final mallsSnapshot = await _firestore.collection('malls').get();

    for (var mallDoc in mallsSnapshot.docs) {
      await deleteMall(mallDoc.id);
    }
  }

  // Delete a specific slot
  Future<void> deleteSlot(String slotId, String mallId) async {
    final batch = _firestore.batch();

    // Delete from global slots
    batch.delete(_firestore.collection('slots').doc(slotId));

    // Delete from nested slots
    batch.delete(
      _firestore
          .collection('malls')
          .doc(mallId)
          .collection('slots')
          .doc(slotId),
    );

    await batch.commit();
  }

  // Delete all slots for a mall
  Future<void> deleteAllSlots(String mallId) async {
    final batch = _firestore.batch();

    // Delete global slots
    final slotsSnapshot = await _firestore
        .collection('slots')
        .where('mallId', isEqualTo: mallId)
        .get();
    for (var doc in slotsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete nested slots
    final nestedSlotsSnapshot = await _firestore
        .collection('malls')
        .doc(mallId)
        .collection('slots')
        .get();
    for (var doc in nestedSlotsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    // Update mall counters
    await _firestore.collection('malls').doc(mallId).update({
      'totalSlots': 0,
      'availableSlots': 0,
      'occupiedSlots': 0,
      'petrolSlots': 0,
      'evSlots': 0,
    });
  }

  // Clear all active bookings for a mall
  Future<void> clearActiveBookings(String mallId) async {
    final batch = _firestore.batch();

    // Get active bookings from subcollection
    final activeBookingsSnapshot = await _firestore
        .collection('malls')
        .doc(mallId)
        .collection('activeBookings')
        .get();

    // Delete from subcollection and global collection
    for (var doc in activeBookingsSnapshot.docs) {
      batch.delete(doc.reference);

      // Also delete from global bookings collection
      batch.delete(_firestore.collection('bookings').doc(doc.id));
    }

    await batch.commit();
  }

  // Clear booking history for a mall
  Future<void> clearBookingHistory(String mallId) async {
    final batch = _firestore.batch();

    // Get booking history from subcollection
    final historySnapshot = await _firestore
        .collection('malls')
        .doc(mallId)
        .collection('bookingHistory')
        .get();

    // Delete from subcollection and global collection
    for (var doc in historySnapshot.docs) {
      batch.delete(doc.reference);

      // Also delete from global bookings collection
      batch.delete(_firestore.collection('bookings').doc(doc.id));
    }

    await batch.commit();
  }

  // Get mall statistics
  Future<Map<String, dynamic>> getMallStatistics(String mallId) async {
    final mallDoc = await _firestore.collection('malls').doc(mallId).get();

    if (!mallDoc.exists) {
      throw Exception('Mall not found');
    }

    final mallData = mallDoc.data()!;

    // Get active bookings count
    final activeBookingsSnapshot = await _firestore
        .collection('malls')
        .doc(mallId)
        .collection('activeBookings')
        .get();

    // Get total bookings from history
    final historySnapshot = await _firestore
        .collection('malls')
        .doc(mallId)
        .collection('bookingHistory')
        .get();

    final totalEarnings = historySnapshot.docs.fold<num>(0, (sum, doc) {
      final data = doc.data();
      final amount = data['amount'];
      if (amount is num) {
        return sum + amount;
      }
      return sum;
    });

    return {
      'totalSlots': mallData['totalSlots'],
      'availableSlots': mallData['availableSlots'],
      'occupiedSlots': mallData['occupiedSlots'],
      'petrolSlots': mallData['petrolSlots'],
      'evSlots': mallData['evSlots'],
      'activeBookings': activeBookingsSnapshot.docs.length,
      'totalCompletedBookings': historySnapshot.docs.length,
      'totalEarnings': totalEarnings.toDouble(),
      'occupancyRate':
          (mallData['occupiedSlots'] / mallData['totalSlots'] * 100)
              .toStringAsFixed(1),
    };
  }

  // Delete all bookings for a specific mall from global collection
  Future<void> deleteBooking(String mallId) async {
    final batch = _firestore.batch();

    // Get all bookings for this mall from global collection
    final bookingsSnapshot = await _firestore
        .collection('bookings')
        .where('mallId', isEqualTo: mallId)
        .get();

    // Delete all bookings for this mall
    for (var doc in bookingsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
