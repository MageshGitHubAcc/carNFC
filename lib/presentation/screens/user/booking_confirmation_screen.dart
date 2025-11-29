import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/global_booking_model.dart';
import '../../../data/models/mall_model.dart';
import '../../../data/models/parking_slot_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/provider.dart';

class BookingConfirmationArgs {
  BookingConfirmationArgs({
    required this.mall,
    required this.slot,
    required this.carNumber,
    required this.carType,
    required this.vehicleCategory,
    this.reservationStartTime,
    this.reservationEndTime,
  });

  final MallModel mall;
  final ParkingSlotModel slot;
  final String carNumber;
  final String carType;
  final String vehicleCategory;
  final DateTime? reservationStartTime;
  final DateTime? reservationEndTime;
}

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  const BookingConfirmationScreen({super.key, required this.args});

  static const routeName = '/booking-confirmation';

  final BookingConfirmationArgs args;

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen> {
  bool _isSubmitting = false;
  late DateTime _reservationStartTime;
  late DateTime _reservationEndTime;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Set default reservation time to now + 10 minutes
    final now = DateTime.now();
    _reservationStartTime =
        widget.args.reservationStartTime ??
        now.add(const Duration(minutes: 10));
    _reservationEndTime =
        widget.args.reservationEndTime ?? now.add(const Duration(hours: 1));
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Confirm booking'),
        backgroundColor: const Color(0xFFF4F6FB),
        elevation: 0,
        foregroundColor: const Color(0xFF111D33),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryRow(
                        slotNumber: widget.args.slot.slotNumber,
                        floor: widget.args.slot.floor ?? 'Level 1',
                        zone: widget.args.slot.zone ?? 'A',
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _ReservationTimeSection(
                              startTime: _reservationStartTime,
                              endTime: _reservationEndTime,
                              onStartTimePressed: _selectStartTime,
                              onEndTimePressed: _selectEndTime,
                            ),
                            const SizedBox(height: 16),
                            _BreakdownSection(
                              ratePerHour: 40,
                              carNumber: widget.args.carNumber,
                              carType: widget.args.carType,
                              startTime: _reservationStartTime,
                              endTime: _reservationEndTime,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      userAsync.when(
                        data: (user) => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2A7CF6),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: _isSubmitting || user == null
                                ? null
                                : () => _handleBooking(user),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Book',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Text('Failed to load user'),
                      ),
                      const SizedBox(height: 16), // Add some bottom padding
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reservationStartTime),
    );
    if (picked != null) {
      setState(() {
        _reservationStartTime = DateTime(
          _reservationStartTime.year,
          _reservationStartTime.month,
          _reservationStartTime.day,
          picked.hour,
          picked.minute,
        );
        // Ensure end time is after start time
        if (_reservationEndTime.isBefore(
          _reservationStartTime.add(const Duration(minutes: 15)),
        )) {
          _reservationEndTime = _reservationStartTime.add(
            const Duration(hours: 1),
          );
        }
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reservationEndTime),
    );
    if (picked != null) {
      setState(() {
        final newEndTime = DateTime(
          _reservationEndTime.year,
          _reservationEndTime.month,
          _reservationEndTime.day,
          picked.hour,
          picked.minute,
        );
        // Ensure end time is at least 15 minutes after start time
        if (newEndTime.isAfter(
          _reservationStartTime.add(const Duration(minutes: 15)),
        )) {
          _reservationEndTime = newEndTime;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'End time must be at least 15 minutes after start time',
              ),
            ),
          );
        }
      });
    }
  }

  Future<void> _handleBooking(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);
      final uniqueId = 'BK-${DateTime.now().millisecondsSinceEpoch}';
      final bookingId = await _generateSerialBookingId();

      // Create the booking model with all required fields
      final bookingModel = GlobalBookingModel(
        bookingId: bookingId,
        userId: user.uid,
        userName: user.name,
        mallId: widget.args.mall.mallId,
        mallName: widget.args.mall.name,
        uniqueId: uniqueId,
        slotId: widget.args.slot.slotId,
        slotNumber: widget.args.slot.slotNumber,
        carNumber: widget.args.carNumber,
        carType: widget.args.carType,
        vehicleCategory: widget.args.vehicleCategory,
        checkInDateTime: DateTime.now(),
        status: BookingStatus.reserved,
        duration: null,
        reservationStartTime: _reservationStartTime,
        reservationEndTime: _reservationEndTime,
        encryptedData: '',
        createdAt: DateTime.now(),
      );

      // Create the booking - this will handle the slot update in the batch operation
      await bookingRepo.createBooking(
        userId: user.uid,
        userName: user.name,
        userEmail: user.email,
        booking: bookingModel,
        mallName: widget.args.mall.name,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parking slot reserved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to home screen
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } on FirebaseException catch (e, s) {
      log('Firebase error: ${e.message}', error: e, stackTrace: s);
      String errorMessage = 'Booking failed: ${e.message}';
      if (e.code == 'not-found') {
        errorMessage = 'Could not find the parking slot. Please try again.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e, s) {
      log('Unexpected error: $e', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<String> _generateSerialBookingId() async {
    final counterRef = FirebaseFirestore.instance
        .collection('metadata')
        .doc('booking_counter');

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      int currentValue = 0;

      if (snapshot.exists) {
        currentValue = (snapshot.data()?['value'] as int?) ?? 0;
        transaction.update(counterRef, {'value': currentValue + 1});
      } else {
        transaction.set(counterRef, {'value': 1});
        currentValue = 0;
      }

      final serialNumber = currentValue + 1;
      return 'BK-${serialNumber.toString().padLeft(6, '0')}';
    });
  }
}

class _ReservationTimeSection extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;
  final VoidCallback onStartTimePressed;
  final VoidCallback onEndTimePressed;

  const _ReservationTimeSection({
    required this.startTime,
    required this.endTime,
    required this.onStartTimePressed,
    required this.onEndTimePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reservation Time',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'From',
                    time: startTime,
                    onPressed: onStartTimePressed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeButton(
                    label: 'To',
                    time: endTime,
                    onPressed: onEndTimePressed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Duration: ${_formatDuration(endTime.difference(startTime))}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${twoDigits(hours)}h ${twoDigits(minutes)}m';
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final DateTime time;
  final VoidCallback onPressed;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(time),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Icon(Icons.access_time, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour < 12 ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.slotNumber,
    required this.floor,
    required this.zone,
  });

  final int slotNumber;
  final String floor;
  final String zone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parking Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111D33),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.local_parking,
                  title: 'Parking Spot',
                  value: '#$slotNumber',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: Icons.stairs,
                  title: 'Level',
                  value: floor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: Icons.grid_view,
                  title: 'Zone',
                  value: zone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.valueStyle,
  });

  final IconData icon;
  final String title;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style:
                      valueStyle ??
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111D33),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Removed unused _PaymentCard widget

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({
    required this.ratePerHour,
    required this.carNumber,
    required this.carType,
    required this.startTime,
    required this.endTime,
  });

  final int ratePerHour;
  final String carNumber;
  final String carType;
  final DateTime startTime;
  final DateTime endTime;

  String _formatDate(DateTime date) {
    return '${_getWeekday(date.weekday)}, ${date.day} ${_getMonth(date.month)} ${date.year}';
  }

  String _getWeekday(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour < 12 ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final duration = endTime.difference(startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final totalHours = hours + (minutes / 60);
    final totalAmount = (totalHours * ratePerHour).toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111D33),
            ),
          ),
          const SizedBox(height: 16),
          _InfoTile(
            icon: Icons.calendar_today,
            title: 'Date',
            value: _formatDate(startTime),
          ),
          _InfoTile(
            icon: Icons.access_time,
            title: 'Time Slot',
            value: '${_formatTime(startTime)} - ${_formatTime(endTime)}',
          ),
          _InfoTile(
            icon: Icons.timer,
            title: 'Duration',
            value: '${hours}h ${minutes}m',
          ),
          const Divider(height: 32, thickness: 1),
          const Text(
            'Pricing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111D33),
            ),
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.local_parking,
            title: 'Parking Rate',
            value: '₹$ratePerHour/hour',
          ),
          _InfoTile(
            icon: Icons.schedule,
            title: 'Total Time',
            value: '${hours}h ${minutes}m',
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.receipt,
            title: 'Total Amount',
            value: '₹$totalAmount',
            valueStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A7CF6),
            ),
          ),
        ],
      ),
    );
  }
}
