import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/presentation/screens/admin/manual_booking_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final mallsAsync = ref.watch(adminMallsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      body: mallsAsync.when(
        data: (malls) {
          if (malls.isEmpty) {
            return const Center(child: Text('No malls configured yet.'));
          }
          _ensureMallSelected(malls);
          final selectedMall = malls.firstWhere(
            (m) => m.mallId == _selectedMallId,
          );

          final statsAsync = ref.watch(
            mallStatisticsProvider(selectedMall.mallId),
          );
          final slotsAsync = ref.watch(
            slotsForMallProvider(selectedMall.mallId),
          );

          return RefreshIndicator(
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
                      const _QuickActionsSection(),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
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
    if (_selectedMallId == null && malls.isNotEmpty) {
      _selectedMallId = malls.first.mallId;
    }
  }

  void openUserScreen() {
    Navigator.pushNamed(context, 'profile_screen');
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
    final occupiedPercent = (mall.occupiedSlots / total * 100).toStringAsFixed(
      1,
    );

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
                value: '${mall.occupiedSlots}',
                subtitle: '$occupiedPercent% of total',
                icon: Icons.directions_car,
                color: const Color(0xFFF97316),
              ),
            ),
            DashboardStatCard(
              data: StatCardData(
                title: 'Active Bookings',
                value: '${stats['activeBookings'] ?? 0}',
                icon: Icons.confirmation_number,
                color: const Color(0xFF8B5CF6),
              ),
            ),
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
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        label: 'Active Bookings',
        icon: Icons.list_alt_rounded,
        color: Colors.green,
        route: '/admin/active-bookings',
      ),
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
