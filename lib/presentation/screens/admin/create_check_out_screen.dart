import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/global_booking_model.dart';
import '../../../data/providers/provider.dart';

class CreateCheckOutArgs {
  final GlobalBookingModel booking;

  CreateCheckOutArgs({required this.booking});
}

class CreateCheckOutScreen extends ConsumerStatefulWidget {
  const CreateCheckOutScreen({super.key, required this.booking});

  static const routeName = '/admin/checkout';

  final GlobalBookingModel booking;

  @override
  ConsumerState<CreateCheckOutScreen> createState() =>
      _CreateCheckOutScreenState();
}

class _CreateCheckOutScreenState extends ConsumerState<CreateCheckOutScreen> {
  Timer? _timer;
  Duration _liveDuration = Duration.zero;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _updateDuration();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateDuration(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateDuration() {
    final booking = widget.booking;
    setState(() {
      _liveDuration = DateTime.now().difference(booking.checkInDateTime);
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Edit Status'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CheckoutHeader(booking: booking, liveDuration: _liveDuration),
              const SizedBox(height: 20),
              _InfoCard(
                title: 'Slot & Vehicle',
                icon: Icons.local_parking,
                children: [
                  _InfoRow(label: 'Mall', value: booking.mallName),
                  _InfoRow(
                    label: 'Slot Number',
                    value: 'P ${booking.slotNumber}',
                  ),
                  _InfoRow(label: 'Vehicle Number', value: booking.carNumber),
                  _InfoRow(
                    label: 'Vehicle Type',
                    value: booking.vehicleCategory,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'User Details',
                icon: Icons.person_outline,
                children: [
                  _InfoRow(label: 'Name', value: booking.userName),
                  _InfoRow(label: 'User ID', value: booking.userId),
                ],
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Timing',
                icon: Icons.schedule,
                children: [
                  _InfoRow(
                    label: 'Check-in Time',
                    value: _formatDateTime(booking.checkInDateTime),
                  ),
                  _InfoRow(
                    label: 'Current Duration',
                    value: _formatDuration(_liveDuration),
                  ),
                  _InfoRow(
                    label: 'Checkout Time',
                    value: _formatDateTime(DateTime.now()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Actions & Impact',
                icon: Icons.warning_amber_rounded,
                accentColor: const Color(0xFFFFE8D2),
                children: const [
                  _ImpactRow(text: 'Release slot back to available pool'),
                  _ImpactRow(text: 'Mark booking as completed'),
                  _ImpactRow(text: 'Update mall statistics'),
                  _ImpactRow(text: 'Notify user about checkout'),
                  _ImpactRow(text: 'Move booking to history'),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _ErrorBanner(message: _errorMessage!),
              ],
              const SizedBox(height: 24),
              // Show different buttons based on booking status
              if (booking.status == BookingStatus.reserved) ...[
                // Reserved status: 3 buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _handleCancelReserve,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel Reserve'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : _handleConvertToCheckIn,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Convert to Check-in'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _handleEditDetails,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Active/Occupied status: 2 buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _handleCheckout,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          _isProcessing ? 'Processing...' : 'Confirm Checkout',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCheckout() async {
    final booking = widget.booking;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);

      // Checkout should mark booking as completed, not active
      await bookingRepo.updateBookingStatus(
        bookingId: booking.bookingId,
        status: 'completed',
        mallId: booking.mallId,
        slotId: booking.slotId,
        userId: booking.userId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checkout completed successfully.')),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/admin/dashboard',
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleCancelReserve() async {
    final booking = widget.booking;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);

      // Cancel the reservation - this will update slot status to available
      await bookingRepo.updateBookingStatus(
        bookingId: booking.bookingId,
        status: 'cancelled',
        mallId: booking.mallId,
        slotId: booking.slotId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation cancelled successfully.')),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/admin/dashboard',
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleConvertToCheckIn() async {
    final booking = widget.booking;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);

      // Convert reserved to active (check-in)
      await bookingRepo.updateBookingStatus(
        bookingId: booking.bookingId,
        status: 'active',
        mallId: booking.mallId,
        slotId: booking.slotId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Converted to check-in successfully.')),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/admin/dashboard',
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _handleEditDetails() {
    // Navigate to ManualBookingScreen with existing booking data
    Navigator.pushReplacementNamed(
      context,
      '/admin/manual-booking',
      arguments: {
        'slot': widget.booking,
        'mallId': widget.booking.mallId,
        'existingBooking': widget.booking,
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • $hour:$minute';
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      return '0 min';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader({required this.booking, required this.liveDuration});

  final GlobalBookingModel booking;
  final Duration liveDuration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFE0F2FE),
                child: Icon(Icons.directions_car, color: Color(0xFF0369A1)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking #${booking.bookingId}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Vehicle ${booking.carNumber} • Slot P ${booking.slotNumber}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryChip(
                  label: 'Current Duration',
                  value: _formatLiveDuration(liveDuration),
                  icon: Icons.timelapse,
                ),
                _SummaryChip(
                  label: 'Status',
                  value: booking.status.name.toUpperCase(),
                  icon: Icons.info_outline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLiveDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white,
          child: Icon(icon, color: const Color(0xFF0F172A), size: 18),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
    this.accentColor,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accentColor ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: accentColor == null
            ? const [BoxShadow(color: Color(0x11000000), blurRadius: 14)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0F172A)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.arrow_right, color: Color(0xFFDC2626)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFB91C1C)),
            ),
          ),
        ],
      ),
    );
  }
}
