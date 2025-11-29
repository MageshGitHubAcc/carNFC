import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/parking_history_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's parking history for a specific mall
  Stream<List<ParkingHistoryModel>> getParkingHistoryByMall({
    required String userId,
    required String mallId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('parkingHistory')
        .where('mallId', isEqualTo: mallId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ParkingHistoryModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get all parking history for user (across all malls)
  Stream<List<ParkingHistoryModel>> getAllParkingHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('parkingHistory')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ParkingHistoryModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get active parking (status = 'active')
  Stream<List<ParkingHistoryModel>> getActiveParkings(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('parkingHistory')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ParkingHistoryModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Check if user has active parking in a mall
  Future<ParkingHistoryModel?> getActiveParkingInMall({
    required String userId,
    required String mallId,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('parkingHistory')
        .where('mallId', isEqualTo: mallId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return ParkingHistoryModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Add parking to user's history (called when booking is created)
  Future<void> addParkingToHistory({
    required String userId,
    required String bookingId,
    required ParkingHistoryModel parking,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('parkingHistory')
        .doc(bookingId)
        .set(parking.toFirestore());
  }

  // Update parking history (when checking out)
  Future<void> updateParkingHistory({
    required String userId,
    required String bookingId,
    required DateTime checkOutDateTime,
    required String duration,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('parkingHistory')
        .doc(bookingId)
        .update({
      'checkOutDateTime': Timestamp.fromDate(checkOutDateTime),
      'status': 'completed',
      'duration': duration,
    });
  }

  // Get parking statistics for user
  Future<Map<String, dynamic>> getUserParkingStats(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('parkingHistory')
        .get();

    int totalParkings = snapshot.docs.length;
    int activeParkings =
        snapshot.docs.where((doc) => doc.data()['status'] == 'active').length;
    int completedParkings = snapshot.docs
        .where((doc) => doc.data()['status'] == 'completed')
        .length;

    // Get unique malls visited
    Set<String> mallsVisited = {};
    for (var doc in snapshot.docs) {
      mallsVisited.add(doc.data()['mallId'] as String);
    }

    return {
      'totalParkings': totalParkings,
      'activeParkings': activeParkings,
      'completedParkings': completedParkings,
      'mallsVisited': mallsVisited.length,
    };
  }

  // Delete parking from history (admin only)
  Future<void> deleteParkingHistory({
    required String userId,
    required String bookingId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('parkingHistory')
        .doc(bookingId)
        .delete();
  }
}
