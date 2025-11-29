import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/data/models/global_booking_model.dart';
import 'package:flutter_app/data/providers/provider.dart';
import 'package:flutter_app/presentation/screens/admin/dashboard_components.dart';
import 'package:flutter_app/presentation/screens/admin/create_check_out_screen.dart';

class ActiveBookingsScreen extends ConsumerStatefulWidget {
  static const String routeName = '/admin/active-bookings';

  const ActiveBookingsScreen({super.key});

  @override
  ConsumerState<ActiveBookingsScreen> createState() =>
      _ActiveBookingsScreenState();
}

class _ActiveBookingsScreenState extends ConsumerState<ActiveBookingsScreen> {
  String? _selectedMallId;

  @override
  Widget build(BuildContext context) {
    final mallsAsync = ref.watch(adminMallsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Active Bookings'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 1,
      ),
      body: mallsAsync.when(
        data: (malls) {
          if (malls.isEmpty) {
            return const Center(child: Text('No malls configured.'));
          }

          // Get all active bookings
          final bookingsAsync = ref.watch(activeBookingsProvider);

          return Column(
            children: [
              // Mall Filter Dropdown
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: DropdownButtonFormField<String?>(
                  value: _selectedMallId,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Mall',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Malls'),
                    ),
                    ...malls.map(
                      (mall) => DropdownMenuItem(
                        value: mall.mallId,
                        child: Text(mall.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedMallId = value),
                ),
              ),

              // Bookings List
              Expanded(
                child: bookingsAsync.when(
                  data: (bookings) {
                    // Filter bookings by selected mall
                    final filteredBookings = _selectedMallId == null
                        ? bookings
                        : bookings
                              .where((b) => b.mallId == _selectedMallId)
                              .toList();

                    if (filteredBookings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedMallId == null
                                  ? 'No Active Bookings'
                                  : 'No Active Bookings for this Mall',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All slots are available',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(activeBookingsProvider);
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          return DashboardBookingCard(
                            booking: booking,
                            onCheckout: () =>
                                _openCheckoutScreen(context, booking),
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(activeBookingsProvider);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _openCheckoutScreen(BuildContext context, GlobalBookingModel booking) {
    Navigator.pushNamed(
      context,
      CreateCheckOutScreen.routeName,
      arguments: CreateCheckOutArgs(booking: booking),
    );
  }
}
