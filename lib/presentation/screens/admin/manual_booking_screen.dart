import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/data/models/global_booking_model.dart';
import 'package:flutter_app/data/models/parking_slot_model.dart';
import 'package:flutter_app/data/providers/provider.dart';
import 'package:flutter_app/core/services/nfc_service.dart';

class ManualBookingScreen extends ConsumerStatefulWidget {
  static const String routeName = 'manual_booking_screen';

  final ParkingSlotModel slot;
  final String mallId;
  final GlobalBookingModel? existingBooking;

  const ManualBookingScreen({
    super.key,
    required this.slot,
    required this.mallId,
    this.existingBooking,
  });

  @override
  ConsumerState<ManualBookingScreen> createState() =>
      _ManualBookingScreenState();
}

class _ManualBookingScreenState extends ConsumerState<ManualBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _carNumberController = TextEditingController();
  final _carModelController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nfcService = NFCService();

  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill form if existing booking is provided
    if (widget.existingBooking != null) {
      _nameController.text = widget.existingBooking!.userName;
      _carNumberController.text = widget.existingBooking!.carNumber;
      _carModelController.text = widget.existingBooking!.carType;
      // Phone number might not be in the booking model, leave empty if not available
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _carNumberController.dispose();
    _carModelController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateOnly() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating booking...';
    });

    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);
      final bookingId = FirebaseFirestore.instance
          .collection('bookings')
          .doc()
          .id;
      final now = DateTime.now();

      final booking = GlobalBookingModel(
        bookingId: bookingId,
        userId: 'manual_entry',
        userName: _nameController.text,
        mallId: widget.mallId,
        mallName: 'Mall',
        uniqueId: 'MANUAL-${now.millisecondsSinceEpoch}',
        slotId: widget.slot.slotId,
        slotNumber: widget.slot.slotNumber,
        carNumber: _carNumberController.text.toUpperCase(),
        carType: _carModelController.text,
        vehicleCategory: '4 Wheeler',
        checkInDateTime: now,
        status: BookingStatus.active, // Active status for manual occupancy
        encryptedData: '',
        createdAt: now,
        reservationStartTime: now,
        reservationEndTime: now.add(const Duration(hours: 24)),
      );

      await bookingRepo.createBooking(
        userId: 'manual_entry',
        userName: _nameController.text,
        userEmail: 'admin@parking.com',
        booking: booking,
        mallName: 'Mall',
      );

      if (mounted) {
        // Wait a moment for Firebase to propagate changes
        await Future.delayed(const Duration(milliseconds: 500));

        // Invalidate providers to refresh dashboard
        ref.invalidate(slotsForMallProvider(widget.mallId));
        ref.invalidate(activeBookingsForMallProvider(widget.mallId));
        ref.invalidate(mallStatisticsProvider(widget.mallId));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
        });
      }
    }
  }

  Future<void> _handleCreateAndWrite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating booking...';
    });

    try {
      // 1. Create Booking
      final bookingRepo = ref.read(bookingRepositoryProvider);
      final bookingId = FirebaseFirestore.instance
          .collection('bookings')
          .doc()
          .id;
      final now = DateTime.now();

      final booking = GlobalBookingModel(
        bookingId: bookingId,
        userId: 'manual_entry',
        userName: _nameController.text,
        mallId: widget.mallId,
        mallName: 'Mall', // Ideally fetch from provider
        uniqueId: 'MANUAL-${now.millisecondsSinceEpoch}',
        slotId: widget.slot.slotId,
        slotNumber: widget.slot.slotNumber,
        carNumber: _carNumberController.text.toUpperCase(),
        carType: _carModelController.text,
        vehicleCategory: '4 Wheeler',
        checkInDateTime: now,
        status: BookingStatus.active, // Active status for manual occupancy
        encryptedData: '',
        createdAt: now,
        reservationStartTime: now,
        reservationEndTime: now.add(const Duration(hours: 24)),
      );

      await bookingRepo.createBooking(
        userId: 'manual_entry',
        userName: _nameController.text,
        userEmail: 'admin@parking.com',
        booking: booking,
        mallName: 'Mall',
      );

      // 2. Write to NFC
      setState(() {
        _statusMessage = 'Hold NFC tag near device to write...';
      });

      // Check NFC availability
      final isNfcAvailable = await _nfcService.isNFCAvailable();
      if (!isNfcAvailable) {
        _showError(
          'NFC is not available on this device. Booking created without NFC.',
        );
        if (mounted) Navigator.pop(context);
        return;
      }

      // Check if there are any occupied slots before writing to NFC
      final slotsAsync = ref.read(slotsForMallProvider(widget.mallId));
      final slots = slotsAsync.value ?? [];
      final occupiedSlots = slots
          .where(
            (slot) =>
                slot.status.toLowerCase() == 'occupied' ||
                slot.status.toLowerCase() == 'active',
          )
          .toList();

      if (occupiedSlots.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No occupied slots found. NFC tag not written.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final nfcData = {
        'bookingId': bookingId,
        'carNumber': booking.carNumber,
        'slotNumber': booking.slotNumber,
        'mallId': booking.mallId,
        'checkInTime': now.toIso8601String(),
      };

      final success = await _nfcService.writeNFCTag(nfcData);

      if (mounted) {
        // Wait a moment for Firebase to propagate changes
        await Future.delayed(const Duration(milliseconds: 500));

        // Invalidate providers to refresh dashboard
        ref.invalidate(slotsForMallProvider(widget.mallId));
        ref.invalidate(activeBookingsForMallProvider(widget.mallId));
        ref.invalidate(mallStatisticsProvider(widget.mallId));
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking created and NFC written successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        _showError('Failed to write NFC tag. Booking created.');
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Booking'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSlotInfo(),
              const SizedBox(height: 32),
              const Text(
                'Vehicle Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _carNumberController,
                label: 'Car Number',
                icon: Icons.directions_car,
                isCapitalized: true,
                enabled: widget.existingBooking == null,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _carModelController,
                label: 'Car Model',
                icon: Icons.local_taxi,
                enabled: widget.existingBooking == null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Driver Name',
                icon: Icons.person,
                enabled: widget.existingBooking == null,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              if (widget.existingBooking != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Existing reservation details are shown above. You can update the phone number if needed.',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 40),
              if (_statusMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleCreateOnly,
                        icon: const Icon(Icons.bookmark_add),
                        label: const Text(
                          'Create Only',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                          side: const BorderSide(
                            color: Color(0xFF3B82F6),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleCreateAndWrite,
                        icon: const Icon(Icons.nfc),
                        label: const Text(
                          'Create & NFC',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.local_parking,
              size: 32,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Slot P${widget.slot.slotNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.slot.floor ?? 'Ground'} Floor • ${widget.slot.zone ?? 'Zone A'}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isCapitalized = false,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF8FAFC),
      ),
      textCapitalization: isCapitalized
          ? TextCapitalization.characters
          : TextCapitalization.words,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
