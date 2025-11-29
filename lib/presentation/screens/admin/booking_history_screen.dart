import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../data/models/global_booking_model.dart';
import '../../../../data/repositories/booking_repository.dart';

class BookingHistoryScreen extends ConsumerStatefulWidget {
  final String? initialMallId;
  const BookingHistoryScreen({super.key, this.initialMallId});
  static const routeName = '/admin/booking-history';

  @override
  ConsumerState<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedMallId;
  final _dateRange = <DateTime?>[null, null];
  final _itemsPerPage = 10;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final _bookings = <GlobalBookingModel>[];

  @override
  void initState() {
    super.initState();
    _selectedMallId = widget.initialMallId;
    _loadBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _lastDocument = null;
        _hasMore = true;
        _bookings.clear();
      });
    }

    if (!_hasMore && loadMore) return;

    setState(() => _isLoadingMore = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('checkInDateTime', descending: true)
          .limit(_itemsPerPage);

      // Apply filters
      if (_selectedMallId != null) {
        query = query.where('mallId', isEqualTo: _selectedMallId);
      }

      if (_selectedStatus != null) {
        query = query.where('status', isEqualTo: _selectedStatus);
      }

      if (_dateRange[0] != null) {
        query = query.where(
          'checkInDateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_dateRange[0]!),
        );
      }

      if (_dateRange[1] != null) {
        final endOfDay = DateTime(
          _dateRange[1]!.year,
          _dateRange[1]!.month,
          _dateRange[1]!.day,
          23,
          59,
          59,
        );
        query = query.where(
          'checkInDateTime',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
        );
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty && loadMore) {
        setState(() => _hasMore = false);
        return;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      final newBookings = snapshot.docs
          .map((doc) => GlobalBookingModel.fromFirestore(doc))
          .toList();

      if (loadMore) {
        setState(() {
          _bookings.addAll(newBookings);
          _isLoadingMore = false;
          _hasMore = newBookings.length == _itemsPerPage;
        });
      } else {
        setState(() {
          _bookings.addAll(newBookings);
          _isLoadingMore = false;
          _hasMore = newBookings.length == _itemsPerPage;
        });
      }
    } catch (e) {
      print(e);
      setState(() => _isLoadingMore = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading bookings: $e')));
      }
    }
  }

  Future<void> _showFilters(BuildContext context) async {
    final mallsSnapshot = await FirebaseFirestore.instance
        .collection('malls')
        .get();
    final malls = mallsSnapshot.docs;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Bookings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedMallId,
                decoration: const InputDecoration(
                  labelText: 'Mall',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Malls')),
                  ...malls.map(
                    (mall) => DropdownMenuItem(
                      value: mall.id,
                      child: Text(mall['name']),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedMallId = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Statuses'),
                  ),
                  ...['active', 'completed', 'cancelled'].map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(
                        status[0].toUpperCase() + status.substring(1),
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date Range'),
                subtitle: Text(
                  _dateRange[0] == null
                      ? 'Select date range'
                      : '${DateFormat('MMM d, y').format(_dateRange[0]!)} - ${_dateRange[1] != null ? DateFormat('MMM d, y').format(_dateRange[1]!) : ''}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _dateRange[0] = picked.start;
                      _dateRange[1] = picked.end;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedMallId = null;
                _selectedStatus = null;
                _dateRange[0] = null;
                _dateRange[1] = null;
              });
              Navigator.pop(context);
              _loadBookings();
            },
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadBookings();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilters(context),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by car number, slot, or booking ID',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadBookings();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _loadBookings(),
            ),
          ),
          Expanded(
            child: _bookings.isEmpty && !_isLoadingMore
                ? const Center(child: Text('No bookings found'))
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollNotification) {
                      if (scrollNotification is ScrollEndNotification &&
                          scrollNotification.metrics.pixels ==
                              scrollNotification.metrics.maxScrollExtent &&
                          _hasMore &&
                          !_isLoadingMore) {
                        _loadBookings(loadMore: true);
                      }
                      return true;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _bookings.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == _bookings.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final booking = _bookings[index];
                        final checkInDate = booking.checkInDateTime.toLocal();
                        final checkOutDate = booking.checkOutDateTime
                            ?.toLocal();
                        final duration = checkOutDate != null
                            ? checkOutDate.difference(checkInDate)
                            : null;

                        return Card(
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text(
                              'Booking #${booking.bookingId.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Car: ${booking.carNumber}'),
                                Text('Slot: ${booking.slotNumber}'),
                                Text(
                                  'Check-in: ${DateFormat('MMM d, y hh:mm a').format(checkInDate)}',
                                ),
                                if (checkOutDate != null)
                                  Text(
                                    'Check-out: ${DateFormat('MMM d, y hh:mm a').format(checkOutDate)}',
                                  ),
                                if (duration != null)
                                  Text(
                                    'Duration: ${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
                                  ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      booking.status,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    booking.status.name,
                                    style: TextStyle(
                                      color: _getStatusColor(booking.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Show booking details
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.active:
        return Colors.green;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
