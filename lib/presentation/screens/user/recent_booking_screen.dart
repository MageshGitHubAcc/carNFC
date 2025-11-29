// Add these widgets in home_screen.dart or in a separate file

import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/global_booking_model.dart';
import 'package:flutter_app/data/providers/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecentBookingsWidget extends ConsumerWidget {
  const RecentBookingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(activeBookingsProvider);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Bookings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            bookingsAsync.when(
              data: (bookings) {
                if (bookings.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No active bookings'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bookings.take(3).length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return _BookingItem(
                      booking: booking,
                      onCancel: () => _cancelBooking(context, ref, booking),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelBooking(
    BuildContext context,
    WidgetRef ref,
    GlobalBookingModel booking,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(bookingRepositoryProvider)
            .cancelBooking(
              bookingId: booking.bookingId,
              userId: booking.userId,
              mallId: booking.mallId,
              slotId: booking.slotId,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class ParkingHistoryWidget extends ConsumerWidget {
  const ParkingHistoryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();

    final historyAsync = ref.watch(userParkingHistoryProvider(user.uid));

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parking History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No parking history'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    return ListTile(
                      leading: const Icon(Icons.local_parking),
                      title: Text(entry.mallName),
                      subtitle: Text(
                        '${_formatDate(entry.checkInDateTime)} • ${_formatTime(entry.checkInDateTime)}',
                      ),
                      trailing: Text(
                        entry.status.toUpperCase(),
                        style: TextStyle(
                          color: entry.status == 'completed'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _BookingItem extends StatelessWidget {
  final GlobalBookingModel booking;
  final VoidCallback onCancel;

  const _BookingItem({required this.booking, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.local_parking, size: 32),
        title: Text(booking.mallName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Slot: ${booking.slotNumber}'),
            Text('Status: ${booking.status.toString().split('.').last}'),
            if (booking.reservationStartTime != null)
              Text(
                'Time: ${_formatTime(booking.reservationStartTime!)} - ${_formatTime(booking.reservationEndTime!)}',
              ),
          ],
        ),
        trailing: booking.status == BookingStatus.reserved
            ? IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: onCancel,
              )
            : null,
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
