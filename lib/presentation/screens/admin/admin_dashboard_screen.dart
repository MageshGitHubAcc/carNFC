import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/presentation/screens/admin/manual_booking_screen.dart';
import 'package:flutter_app/core/services/nfc_service.dart';

import 'package:flutter_app/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'manage_screen.dart';

import '../../../data/models/global_booking_model.dart';
import '../../../data/models/mall_model.dart';
import '../../../data/models/parking_slot_model.dart';
import '../../../data/providers/provider.dart';
import 'create_check_out_screen.dart';
import 'dashboard_components.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String? _selectedMallId;
  String _selectedFloor = 'All';
  final _nfcService = NFCService();
  bool _isNfcCheckoutProcessing = false;

  Future<void> _navigateToCreateMall() async {
    if (!mounted) return;
    await Navigator.pushNamed(context, '/admin/create-mall');
    // Refresh the malls list after creating a new mall
    if (mounted) {
      ref.invalidate(adminMallsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mallsAsync = ref.watch(adminMallsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50,
      body: mallsAsync.when(
        data: (malls) {
          if (malls.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.store_mall_directory_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No malls configured yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get started by adding your first mall',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCreateMall(),
                    icon: const Icon(Icons.add),
                    label: const Text('CREATE MALL'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          _ensureMallSelected(malls);
          final selectedMall = malls.firstWhere(
            (m) => m.mallId == _selectedMallId,
            orElse: () => malls.first, // Fallback to first mall if not found
          );

          final statsAsync = ref.watch(
            mallStatisticsProvider(selectedMall.mallId),
          );
          final slotsAsync = ref.watch(
            slotsForMallProvider(selectedMall.mallId),
          );

          // Check if there are any occupied slots
          final slots = slotsAsync.value ?? [];
          final hasOccupiedSlots = slots.any(
            (slot) =>
                slot.status.toLowerCase() == 'occupied' ||
                slot.status.toLowerCase() == 'active',
          );

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC), // Slate 50
            floatingActionButton: hasOccupiedSlots
                ? FloatingActionButton.extended(
                    onPressed: _scanNfcForCheckout,
                    icon: const Icon(Icons.nfc),
                    label: const Text('Scan NFC'),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  )
                : null,
            body: RefreshIndicator(
              onRefresh: () async {
                // Refresh all providers for the selected mall
                ref.invalidate(mallStatisticsProvider(selectedMall.mallId));
                ref.invalidate(slotsForMallProvider(selectedMall.mallId));
                ref.invalidate(
                  activeBookingsForMallProvider(selectedMall.mallId),
                );
                // Wait a bit to show the refresh indicator (providers refresh immediately but streams might take a moment)
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(malls, selectedMall),
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Stats Section
                        statsAsync.when(
                          data: (stats) => _StatisticsSection(
                            stats: {...stats, 'mall': selectedMall},
                          ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) =>
                              Text('Error loading stats: $error'),
                        ),
                        const SizedBox(height: 32),

                        // Live Slot Visualization
                        _buildSectionHeader(
                          'Live Slot Visualization',
                          action: _buildFloorFilter(slotsAsync),
                        ),
                        const SizedBox(height: 16),
                        _SlotLegend(),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) =>
                              _buildSlotGrid(constraints, slotsAsync),
                        ),
                        const SizedBox(height: 32),

                        // Quick Actions
                        _buildSectionHeader('Quick Actions'),
                        const SizedBox(height: 16),
                        _QuickActionsSection(
                          onNfcCheckout: _scanNfcForCheckout,
                        ),
                        const SizedBox(height: 40),

                        // Active Bookings Section
                        // _buildSectionHeader('Active Bookings'),
                        // const SizedBox(height: 16),
                        // _buildActiveBookingsSection(),
                        // const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          print(error);
          return Center(child: Text('Error loading malls: $error'));
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(
    List<MallModel> malls,
    MallModel selectedMall,
  ) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        background: Container(color: Colors.white),
      ),
      actions: [
        // Mall Selector
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedMall.mallId,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                  items: malls
                      .map(
                        (mall) => DropdownMenuItem(
                          value: mall.mallId,
                          child: Text(mall.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedMallId = value),
                ),
              ),
            ),
          ),
        ),
        // Profile Icon
        Padding(
          padding: const EdgeInsets.only(right: 24),
          child: IconButton(
            icon: const CircleAvatar(
              backgroundColor: Color(0xFFE2E8F0),
              child: Icon(Icons.person, color: Color(0xFF64748B)),
            ),
            onPressed: openUserScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        if (action != null) ...[const SizedBox(width: 8), action],
      ],
    );
  }

  Widget _buildFloorFilter(AsyncValue<List<ParkingSlotModel>> slotsAsync) {
    return slotsAsync.when(
      data: (slots) {
        final floors =
            slots
                .map((slot) => slot.floor)
                .where((floor) => floor != null && floor.isNotEmpty)
                .toSet()
                .toList()
              ..sort((a, b) => a!.compareTo(b!));

        if (floors.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFloor,
              isDense: true,
              items: [
                const DropdownMenuItem(value: 'All', child: Text('All Floors')),
                ...floors.map(
                  (f) => DropdownMenuItem(value: f, child: Text('Floor $f')),
                ),
              ],
              onChanged: (v) => setState(() => _selectedFloor = v!),
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSlotGrid(
    BoxConstraints constraints,
    AsyncValue<List<ParkingSlotModel>> slotsAsync,
  ) {
    return slotsAsync.when(
      data: (slots) {
        final filtered = slots.where((slot) {
          if (_selectedFloor == 'All') return true;
          return slot.floor == _selectedFloor;
        }).toList();

        if (filtered.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Column(
              children: [
                Icon(Icons.grid_off_rounded, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'No slots found for this floor',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        final int crossAxisCount = (constraints.maxWidth / 80).floor().clamp(
          2,
          10,
        );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final slot = filtered[index];
            return DashboardSlotTile(
              slot: slot,
              onTap: () => _showSlotDetails(slot),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  void _showSlotDetails(ParkingSlotModel slot) async {
    GlobalBookingModel? booking;
    bool isLoading = true;

    // Fetch booking details if slot is not available
    if (slot.status.toLowerCase() != 'available' &&
        slot.currentBookingId != null) {
      try {
        final bookingRepo = ref.read(bookingRepositoryProvider);
        booking = await bookingRepo.getBookingById(slot.currentBookingId!);
      } catch (e) {
        debugPrint('Error fetching booking: $e');
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          if (isLoading &&
              slot.status.toLowerCase() != 'available' &&
              booking == null) {
            // Simulate loading or wait for actual fetch if needed
            // For now, we just set loading to false as we fetched before showing
            // In a real async scenario inside builder, we'd handle state better
            isLoading = false;
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Slot P${slot.slotNumber}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(slot.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(slot.status).withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        slot.status.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _getStatusColor(slot.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Slot Details (Always visible)
                _buildDetailRow('Floor', slot.floor ?? 'Ground'),
                _buildDetailRow('Zone', slot.zone ?? '-'),
                _buildDetailRow('Fuel Type', slot.fuelType.toUpperCase()),

                const Divider(height: 32),

                // Status Specific Details
                if (slot.status.toLowerCase() == 'occupied' &&
                    booking != null) ...[
                  const Text(
                    'Current Session',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('User', booking.userName),
                  _buildDetailRow('Car Number', booking.carNumber),
                  _buildDetailRow(
                    'Vehicle',
                    '${booking.vehicleCategory} (${booking.carType})',
                  ),
                  _buildDetailRow(
                    'Check-in',
                    DateFormat('MMM d, HH:mm').format(booking.checkInDateTime),
                  ),
                  _buildDetailRow(
                    'Duration',
                    _calculateDuration(booking.checkInDateTime),
                  ),
                  _buildDetailRow(
                    'Amount',
                    '₹${_calculateAmount(booking.checkInDateTime)}',
                  ), // Placeholder logic
                ] else if (slot.status.toLowerCase() == 'reserved' &&
                    booking != null) ...[
                  const Text(
                    'Reservation Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('User', booking.userName),
                  _buildDetailRow('Car Number', booking.carNumber),
                  _buildDetailRow(
                    'Reserved For',
                    DateFormat('MMM d, HH:mm').format(
                      booking.reservationStartTime ?? booking.checkInDateTime,
                    ),
                  ),
                ] else if (slot.status.toLowerCase() == 'available') ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Slot is empty and available for booking.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (slot.status.toLowerCase() == 'available')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showManualBookingDialog(slot);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Occupy Slot',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    else if (slot.status.toLowerCase() == 'reserved')
                      Expanded(
                        child: Row(
                          children: [
                            if (booking != null) ...[
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await _handleCheckIn(booking!);
                                    if (mounted) Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Check In',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showManualBookingDialog(slot, booking);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Manual',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (slot.status.toLowerCase() == 'occupied' &&
                        booking != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _openCheckoutScreen(booking!);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Checkout',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xFF10B981);
      case 'occupied':
        return const Color(0xFFEF4444);
      case 'reserved':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _calculateDuration(DateTime checkIn) {
    final duration = DateTime.now().difference(checkIn);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String _calculateAmount(DateTime checkIn) {
    final duration = DateTime.now().difference(checkIn);
    final hours =
        duration.inHours + (duration.inMinutes.remainder(60) > 0 ? 1 : 0);
    return '${hours * 20}'; // Placeholder: ₹20 per hour
  }

  Future<void> _handleCheckIn(GlobalBookingModel booking) async {
    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);
      await bookingRepo.updateBookingStatus(
        bookingId: booking.bookingId,
        status: 'active',
        mallId: booking.mallId,
        slotId: booking.slotId,
        userId: booking.userId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in successful! Slot is now Occupied.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking in: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showManualBookingDialog(
    ParkingSlotModel slot, [
    GlobalBookingModel? existingBooking,
  ]) {
    if (_selectedMallId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualBookingScreen(
          slot: slot,
          mallId: _selectedMallId!,
          existingBooking: existingBooking,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  void _openCheckoutScreen(GlobalBookingModel booking) {
    Navigator.pushNamed(
      context,
      CreateCheckOutScreen.routeName,
      arguments: CreateCheckOutArgs(booking: booking),
    );
  }

  void _ensureMallSelected(List<MallModel> malls) {
    if (malls.isEmpty) return;

    // If no mall is selected or selected mall is not in the list, select the first one
    if (_selectedMallId == null ||
        !malls.any((m) => m.mallId == _selectedMallId)) {
      _selectedMallId = malls.first.mallId;
    }
  }

  void openUserScreen() {
    Navigator.pushNamed(context, 'profile_screen');
  }

  Widget _buildActiveBookingsSection() {
    final activeBookingsAsync = ref.watch(
      activeBookingsForMallProvider(_selectedMallId!),
    );

    return activeBookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.car_rental_outlined,
                  size: 48,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                Text(
                  'No active bookings',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: Column(
            children: [
              // Header with count
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.car_rental, color: Color(0xFF0F172A)),
                    const SizedBox(width: 8),
                    Text(
                      '${bookings.length} Active Booking${bookings.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/admin/active-bookings',
                      ),
                      icon: const Icon(Icons.list_alt, size: 18),
                      label: const Text('View All'),
                    ),
                  ],
                ),
              ),
              // Bookings list (show max 3)
              ...bookings
                  .take(3)
                  .map((booking) => _buildBookingCard(booking))
                  .toList(),
              if (bookings.length > 3)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/admin/active-bookings'),
                    child: Text('View ${bookings.length - 3} more bookings'),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(
              'Error loading bookings',
              style: TextStyle(color: Colors.red[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(GlobalBookingModel booking) {
    final duration = _calculateDuration(booking.checkInDateTime);
    final amount = _calculateAmount(booking.checkInDateTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: booking.status == 'active'
                      ? Colors.green
                      : Colors.orange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  booking.status.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Slot ${booking.slotNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            booking.carNumber,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Check-in: ${DateFormat('hh:mm a').format(booking.checkInDateTime)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                duration,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(amount, style: TextStyle(color: Colors.grey[600])),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _openCheckoutScreen(booking),
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Checkout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _scanNfcForCheckout() async {
    if (_isNfcCheckoutProcessing) return;

    setState(() {
      _isNfcCheckoutProcessing = true;
    });

    try {
      // Check NFC availability
      final isNfcAvailable = await _nfcService.isNFCAvailable();
      if (!isNfcAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NFC is not available on this device'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show scanning dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Scanning NFC Tag'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Hold NFC tag near device to scan...'),
            ],
          ),
        ),
      );

      // Read NFC tag
      final nfcData = await _nfcService.readNFCTag();

      // Close the scanning dialog
      if (!mounted) return;
      Navigator.pop(context);

      if (nfcData == null || nfcData['bookingId'] == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid booking found on NFC tag'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final bookingId = nfcData['bookingId'] as String;

      // Get booking details
      final bookingRepo = ref.read(bookingRepositoryProvider);
      final booking = await bookingRepo.getBookingById(bookingId);

      if (booking == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if booking is already completed
      if (booking.status == BookingStatus.completed) {
        // Clear NFC tag since booking is already completed
        await _nfcService.clearNFCTag();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This booking is already completed. NFC tag cleared.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check if booking is cancelled
      if (booking.status == BookingStatus.cancelled) {
        // Clear NFC tag since booking is cancelled
        await _nfcService.clearNFCTag();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This booking is cancelled. NFC tag cleared.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check if booking is occupied (active or reserved)
      if (booking.status == BookingStatus.active ||
          booking.status == BookingStatus.reserved) {
        // Navigate to checkout screen
        if (!mounted) return;
        await Navigator.pushNamed(
          context,
          CreateCheckOutScreen.routeName,
          arguments: CreateCheckOutArgs(booking: booking),
        );

        // After checkout, clear the NFC tag
        await _nfcService.clearNFCTag();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checkout completed successfully! NFC tag cleared.'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh providers
        ref.invalidate(activeBookingsForMallProvider(_selectedMallId!));
        ref.invalidate(mallStatisticsProvider(_selectedMallId!));
        ref.invalidate(slotsForMallProvider(_selectedMallId!));
      } else {
        // For any other status, clear the NFC tag and show message
        await _nfcService.clearNFCTag();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking status: ${booking.status.name}. NFC tag cleared.',
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('NFC scan failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isNfcCheckoutProcessing = false;
        });
      }
    }
  }
}

class _StatisticsSection extends StatelessWidget {
  const _StatisticsSection({required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final mall = stats['mall'] as MallModel?;
    if (mall == null) return const SizedBox.shrink();

    final total = mall.totalSlots > 0 ? mall.totalSlots : 1;
    final availablePercent = (mall.availableSlots / total * 100)
        .toStringAsFixed(1);
    // final occupiedPercent =
    //     ((mall.occupiedSlots + mall.reservedSlots) / total * 100)
    //         .toStringAsFixed(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1100
            ? 4
            : width > 700
            ? 2
            : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            DashboardStatCard(
              data: StatCardData(
                title: 'Total Capacity',
                value: '${mall.totalSlots}',
                icon: Icons.business,
                color: const Color(0xFF3B82F6),
              ),
            ),
            DashboardStatCard(
              data: StatCardData(
                title: 'Available',
                value: '${mall.availableSlots}',
                subtitle: '$availablePercent% of total',
                trend: 'Live',
                icon: Icons.local_parking,
                color: const Color(0xFF10B981),
              ),
            ),
            DashboardStatCard(
              data: StatCardData(
                title: 'Occupied',
                value: '${mall.occupiedSlots + mall.reservedSlots}',
                subtitle:
                    '${mall.occupiedSlots} active, ${mall.reservedSlots} reserved',
                icon: Icons.directions_car,
                color: const Color(0xFFF97316),
              ),
            ),
            // InkWell(
            //   onTap: () => Navigator.pushNamed(context, AdminRoutes.nfcWrite),
            //   child: Text('write nfc'),
            // ),
            // DashboardStatCard(
            //   data: StatCardData(
            //     title: 'Total Bookings',
            //     value: '${stats['totalCompletedBookings'] ?? 0}',
            //     icon: Icons.confirmation_number,
            //     color: const Color(0xFF8B5CF6),
            //   ),
            // ),
          ],
        );
      },
    );
  }
}

class _SlotLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        DashboardLegendItem(label: 'Available', color: Color(0xFF10B981)),
        DashboardLegendItem(label: 'Occupied', color: Color(0xFFEF4444)),
        DashboardLegendItem(label: 'Reserved', color: Color(0xFFF59E0B)),
        // DashboardLegendItem(label: 'Maintenance', color: Color(0xFF64748B)),
      ],
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({required this.onNfcCheckout});

  final VoidCallback onNfcCheckout;

  @override
  Widget build(BuildContext context) {
    final actions = [
      // _QuickAction(
      //   label: 'Active Bookings',
      //   icon: Icons.list_alt_rounded,
      //   color: Colors.green,
      //   route: '/admin/active-bookings',
      // ),

      // _QuickAction(
      //   label: 'NFC Checkout',
      //   icon: Icons.nfc,
      //   color: Colors.red,
      //   onTap: (context) => onNfcCheckout(),
      // ),
      _QuickAction(
        label: 'Create Mall',
        icon: Icons.add_business_rounded,
        color: Colors.teal,
        onTap: (context) => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ManageScreen()),
        ),
      ),
      _QuickAction(
        label: 'Create Slot',
        icon: Icons.add_location_alt_rounded,
        color: Colors.indigo,
        route: AdminRoutes.manageSlots,
      ),
      // _QuickAction(
      //   label: 'Manage Slots',
      //   icon: Icons.grid_view_rounded,
      //   color: Colors.blue,
      //   route: AdminRoutes.manageSlots,
      // ),
      _QuickAction(
        label: 'History',
        icon: Icons.history_rounded,
        color: Colors.purple,
        route: AdminRoutes.bookingHistory,
      ),
      _QuickAction(
        label: 'Settings',
        icon: Icons.settings_rounded,
        color: Colors.blueGrey,
        route: AdminRoutes.settings,
      ),
      // _QuickAction(
      //   label: 'Manage Data',
      //   icon: Icons.folder_open_rounded,
      //   color: Colors.orange,
      //   onTap: (context) => Navigator.push(
      //     context,
      //     MaterialPageRoute(builder: (context) => const ManageScreen()),
      //   ),
      // ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1200
            ? 7
            : width > 900
            ? 4
            : width > 600
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.5,
          ),
          itemBuilder: (context, index) =>
              _QuickActionButton(action: actions[index]),
        );
      },
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    this.route,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String? route;
  final void Function(BuildContext)? onTap;
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          if (action.onTap != null) {
            action.onTap!(context);
          } else if (action.route != null) {
            Navigator.pushNamed(context, action.route!);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                action.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
