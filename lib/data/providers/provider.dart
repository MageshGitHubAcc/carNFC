import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/booking_history_entry_model.dart';
import 'package:flutter_app/data/models/global_booking_model.dart';
import 'package:flutter_app/data/models/mall_booking_history_entry.dart';
import 'package:flutter_app/data/models/mall_model.dart';
import 'package:flutter_app/data/models/parking_history_model.dart';
import 'package:flutter_app/data/models/parking_slot_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/mall_repository.dart';
import '../repositories/booking_repository.dart';

// ==================== Repository Providers ====================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final mallRepositoryProvider = Provider<MallRepository>((ref) {
  return MallRepository();
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

// ==================== Auth Providers ====================

// Stream of Firebase Auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// Current user data from Firestore
final currentUserDataProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.read(authRepositoryProvider).streamUserData(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// Check if user is admin
final isAdminProvider = Provider<bool>((ref) {
  final userData = ref.watch(currentUserDataProvider);

  return userData.when(
    data: (user) => user?.role == UserRole.admin,
    loading: () => false,
    error: (_, __) => false,
  );
});

// ==================== Mall Providers ====================

// Get all malls
final allMallsProvider = StreamProvider<List<MallModel>>((ref) {
  return ref.watch(mallRepositoryProvider).getMalls(includeInactive: false);
});

// Get all malls for admin (includes inactive)
final adminMallsProvider = StreamProvider<List<MallModel>>((ref) {
  return ref.watch(mallRepositoryProvider).getMalls(includeInactive: true);
});

// Get specific mall by ID
final mallByIdProvider = StreamProvider.family<MallModel?, String>((
  ref,
  mallId,
) {
  return ref.watch(mallRepositoryProvider).streamMallData(mallId);
});

// Get mall statistics
final mallStatisticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, mallId) {
      return ref.watch(mallRepositoryProvider).getMallStatistics(mallId);
    });

// Stream parking slots for a mall
final mallSlotsProvider = StreamProvider.family<List<ParkingSlotModel>, String>(
  (ref, mallId) {
    return ref.watch(mallRepositoryProvider).streamMallSlots(mallId);
  },
);

// Alias for admin dashboard requirements
final slotsForMallProvider =
    StreamProvider.family<List<ParkingSlotModel>, String>((ref, mallId) {
      return ref.watch(mallRepositoryProvider).streamMallSlots(mallId);
    });

// Mall booking history feed
final mallBookingHistoryProvider =
    StreamProvider.family<List<MallBookingHistoryEntry>, String>((ref, mallId) {
      return ref.watch(mallRepositoryProvider).streamMallBookingHistory(mallId);
    });

// ==================== User Parking History Providers ====================

// Get user's parking history for specific mall
final userParkingHistoryByMallProvider =
    StreamProvider.family<List<ParkingHistoryModel>, UserMallQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(userRepositoryProvider)
          .getParkingHistoryByMall(userId: query.userId, mallId: query.mallId);
    });

// Get all parking history for user
final userAllParkingHistoryProvider =
    StreamProvider.family<List<ParkingHistoryModel>, String>((ref, userId) {
      return ref.watch(userRepositoryProvider).getAllParkingHistory(userId);
    });

// Get active parkings for user
final userActiveParkingsProvider =
    StreamProvider.family<List<ParkingHistoryModel>, String>((ref, userId) {
      return ref.watch(userRepositoryProvider).getActiveParkings(userId);
    });

// Check if user has active parking in specific mall
final hasActiveParkingInMallProvider =
    FutureProvider.family<ParkingHistoryModel?, UserMallQuery>((ref, query) {
      return ref
          .watch(userRepositoryProvider)
          .getActiveParkingInMall(userId: query.userId, mallId: query.mallId);
    });

// Get user parking statistics
final userParkingStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) {
      return ref.watch(userRepositoryProvider).getUserParkingStats(userId);
    });

// ==================== Booking Providers ====================

// Get active booking for current user
final activeBookingProvider = StreamProvider<GlobalBookingModel?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref
          .watch(bookingRepositoryProvider)
          .getUserActiveBookings(user.uid)
          .map((bookings) => bookings.isNotEmpty ? bookings.first : null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// Get active bookings for a mall
final activeBookingsForMallProvider =
    StreamProvider.family<List<GlobalBookingModel>, String>((ref, mallId) {
      try {
        return ref
            .watch(bookingRepositoryProvider)
            .getActiveBookingsForMall(mallId);
      } catch (error, stackTrace) {
        debugPrint('Error in activeBookingsForMallProvider: $error');
        debugPrint(stackTrace.toString());
        return Stream.value([]);
      }
    });

// Provider for active bookings
final activeBookingsProvider = StreamProvider<List<GlobalBookingModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  return ref
      .watch(bookingRepositoryProvider)
      .getUserActiveBookings(user.uid)
      .handleError((error, stackTrace) {
        debugPrint('Error in activeBookingsProvider: $error');
        debugPrint(stackTrace.toString());
        return []; // Return empty list on error
      });
});

// Provider for parking history
final userParkingHistoryProvider =
    StreamProvider.family<List<BookingHistoryEntry>, String>((ref, userId) {
      return ref
          .watch(bookingRepositoryProvider)
          .getUserParkingHistory(userId)
          .handleError((error, stackTrace) {
            debugPrint('Error in userParkingHistoryProvider: $error');
            debugPrint(stackTrace.toString());
            return []; // Return empty list on error
          });
    });

// ==================== Helper Classes ====================

class UserMallQuery {
  final String userId;
  final String mallId;

  UserMallQuery({required this.userId, required this.mallId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserMallQuery &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          mallId == other.mallId;

  @override
  int get hashCode => userId.hashCode ^ mallId.hashCode;
}
