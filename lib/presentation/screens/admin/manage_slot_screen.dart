import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/data/models/mall_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/parking_slot_model.dart';
import '../../../../data/providers/provider.dart';

typedef ParkingSlot = ParkingSlotModel;

class ManageSlotsScreen extends ConsumerStatefulWidget {
  final String? initialMallId;
  const ManageSlotsScreen({super.key, this.initialMallId});
  static const routeName = '/admin/manage-slots';

  @override
  ConsumerState<ManageSlotsScreen> createState() => _ManageSlotsScreenState();
}

class _ManageSlotsScreenState extends ConsumerState<ManageSlotsScreen> {
  String? _selectedMallId;
  String _selectedFloor = 'All';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMallId = widget.initialMallId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mallsAsync = ref.watch(adminMallsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Parking Slots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSlotDialog(context, _selectedMallId!),
          ),
        ],
      ),
      body: mallsAsync.when(
        data: (malls) {
          if (malls.isEmpty) {
            return const Center(child: Text('No malls configured yet.'));
          }

          if (_selectedMallId == null) {
            _selectedMallId = malls.first.mallId;
          }

          final selectedMall = malls.firstWhere(
            (m) => m.mallId == _selectedMallId,
            orElse: () => malls.first,
          );

          return Column(
            children: [
              // Mall and floor filter
              _buildFilters(malls, selectedMall),

              // Slots list
              Expanded(child: _buildSlotsList(selectedMall.mallId!)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildFilters(List<MallModel> malls, MallModel selectedMall) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          // Mall dropdown
          DropdownButtonFormField<String>(
            value: _selectedMallId,
            decoration: const InputDecoration(
              labelText: 'Select Mall',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: malls
                .map(
                  (mall) => DropdownMenuItem(
                    value: mall.mallId,
                    child: Text(mall.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedMallId = value;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          // Floor filter
          DropdownButtonFormField<String>(
            value: _selectedFloor,
            decoration: const InputDecoration(
              labelText: 'Select Floor',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: ['All', 'B2', 'B1', 'Ground', '1', '2', '3']
                .map(
                  (floor) => DropdownMenuItem(value: floor, child: Text(floor)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedFloor = value;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search slots...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsList(String mallId) {
    final slotsAsync = ref.watch(slotsForMallProvider(mallId));

    return slotsAsync.when(
      data: (slots) {
        if (slots.isEmpty) {
          return const Center(child: Text('No slots found for this mall.'));
        }

        // Apply filters
        var filteredSlots = slots.where((slot) {
          final matchesFloor =
              _selectedFloor == 'All' ||
              (slot.floor?.toLowerCase() == _selectedFloor.toLowerCase());

          final searchTerm = _searchController.text.toLowerCase();
          final matchesSearch =
              searchTerm.isEmpty ||
              (slot.slotNumber.toString().toLowerCase().contains(searchTerm)) ||
              (slot.floor?.toLowerCase().contains(searchTerm) ?? false);

          return matchesFloor && matchesSearch;
        }).toList();

        // Sort slots by floor and number
        filteredSlots.sort((a, b) {
          final floorCompare = (a.floor ?? '').compareTo(b.floor ?? '');
          if (floorCompare != 0) return floorCompare;
          return a.slotNumber.compareTo(b.slotNumber);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredSlots.length,
          itemBuilder: (context, index) {
            final slot = filteredSlots[index];
            return _buildSlotCard(context, slot);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) {
        print(error);
        return Center(child: Text('Error loading slots: $error'));
      },
    );
  }

  Widget _buildSlotCard(BuildContext context, ParkingSlotModel slot) {
    final status = slot.status.toLowerCase();
    final statusColor =
        {
          'available': Colors.green,
          'occupied': Colors.red,
          'reserved': Colors.orange,
          'maintenance': Colors.blueGrey,
        }[status] ??
        Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: statusColor, width: 2),
          ),
          child: Center(
            child: Text(
              slot.slotNumber.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        title: Text(
          'Slot ${slot.slotNumber} (${slot.fuelType.toUpperCase()})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (slot.floor != null) Text('Floor: ${slot.floor}'),
            Text('Status: ${status.toUpperCase()}'),
            if (slot.zone != null) Text('Zone: ${slot.zone}'),
            if (slot.currentBookingId != null)
              Text('Booking ID: ${slot.currentBookingId}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleSlotAction(context, value, slot),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'toggle', child: Text('Toggle Status')),
            const PopupMenuItem(value: 'edit', child: Text('Edit Slot')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete Slot', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSlotAction(
    BuildContext context,
    String action,
    ParkingSlotModel slot,
  ) async {
    switch (action) {
      case 'toggle':
        await _toggleSlotStatus(slot);
        break;
      case 'edit':
        await _showEditSlotDialog(context, slot);
        break;
      case 'delete':
        await _deleteSlot(slot, _selectedMallId!);
        break;
    }
  }

  Future<void> _toggleSlotStatus(ParkingSlotModel slot) async {
    try {
      final newStatus = slot.status.toLowerCase() == 'available'
          ? 'occupied'
          : 'available';

      await FirebaseFirestore.instance
          .collection('malls')
          .doc(_selectedMallId!)
          .collection('slots')
          .doc(slot.slotId)
          .update({'status': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Slot ${slot.slotNumber} status updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating slot: $e')));
      }
    }
  }

  Future<void> _showAddSlotDialog(BuildContext context, String mallId) async {
    final formKey = GlobalKey<FormState>();
    final slotNumberController = TextEditingController();
    final zoneController = TextEditingController();
    String status = 'available';
    String fuelType = 'petrol';
    String? categoryRestriction;
    bool isChargingStation = false;
    bool isCovered = false;
    bool isHandicapAccessible = false;
    bool isChecking = false;

    // Default floor options
    final floorOptions = ['B2', 'B1', 'Ground', '1', '2', '3', '4', '5'];
    String selectedFloor = '1';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Parking Slot'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Location
                    const Text(
                      'Location Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedFloor,
                            decoration: const InputDecoration(
                              labelText: 'Floor',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: floorOptions
                                .map(
                                  (f) => DropdownMenuItem(
                                    value: f,
                                    child: Text(f),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedFloor = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: slotNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Slot No.',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: zoneController,
                      decoration: const InputDecoration(
                        labelText: 'Zone (Optional)',
                        hintText: 'e.g. A, B, North',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section: Details
                    const Text(
                      'Slot Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: fuelType,
                      decoration: const InputDecoration(
                        labelText: 'Fuel Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_gas_station),
                      ),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'petrol',
                          child: Text('Petrol/Diesel'),
                        ),
                        DropdownMenuItem(
                          value: 'ev',
                          child: Text('Electric (EV)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => fuelType = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: categoryRestriction,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Size',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.directions_car),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Any Size'),
                        ),
                        ...['Compact', 'Standard', 'Large', 'Handicap'].map((
                          category,
                        ) {
                          return DropdownMenuItem(
                            value: category.toLowerCase(),
                            child: Text(category),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() => categoryRestriction = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(
                        labelText: 'Initial Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'available',
                          child: Text('Available'),
                        ),
                        DropdownMenuItem(
                          value: 'occupied',
                          child: Text('Occupied'),
                        ),
                        DropdownMenuItem(
                          value: 'reserved',
                          child: Text('Reserved'),
                        ),
                        DropdownMenuItem(
                          value: 'maintenance',
                          child: Text('Maintenance'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => status = value);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Section: Features
                    const Text(
                      'Features',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text('Charging Station'),
                      value: isChargingStation,
                      onChanged: (val) =>
                          setState(() => isChargingStation = val ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Covered Parking'),
                      value: isCovered,
                      onChanged: (val) =>
                          setState(() => isCovered = val ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Handicap Accessible'),
                      value: isHandicapAccessible,
                      onChanged: (val) =>
                          setState(() => isHandicapAccessible = val ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isChecking
                    ? null
                    : () async {
                        if (formKey.currentState?.validate() ?? false) {
                          setState(() => isChecking = true);
                          try {
                            final slotNum =
                                int.tryParse(
                                  slotNumberController.text.trim(),
                                ) ??
                                0;

                            // Check for duplicate
                            final duplicateQuery = await FirebaseFirestore
                                .instance
                                .collection('malls')
                                .doc(mallId)
                                .collection('slots')
                                .where('slotNumber', isEqualTo: slotNum)
                                .where('floor', isEqualTo: selectedFloor)
                                .get();

                            if (duplicateQuery.docs.isNotEmpty) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Slot $slotNum already exists on Floor $selectedFloor!',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                              setState(() => isChecking = false);
                              return;
                            }

                            final slotData = {
                              'slotNumber': slotNum,
                              'floor': selectedFloor,
                              'zone': zoneController.text.trim().isNotEmpty
                                  ? zoneController.text.trim()
                                  : null,
                              'fuelType': fuelType,
                              'status': status,
                              'categoryRestriction': categoryRestriction,
                              'isChargingStation': isChargingStation,
                              'isCovered': isCovered,
                              'isHandicapAccessible': isHandicapAccessible,
                              'mallId': mallId,
                              'createdAt': FieldValue.serverTimestamp(),
                              'lastUpdated': FieldValue.serverTimestamp(),
                              // Initialize booking fields as null
                              'currentBookingId': null,
                              'currentUserId': null,
                              'reservationEndTime': null,
                            };

                            await FirebaseFirestore.instance
                                .collection('malls')
                                .doc(mallId)
                                .collection('slots')
                                .add(slotData);

                            // Update mall total slots count
                            await FirebaseFirestore.instance
                                .collection('malls')
                                .doc(mallId)
                                .update({
                                  'totalSlots': FieldValue.increment(1),
                                  if (status == 'available')
                                    'availableSlots': FieldValue.increment(1),
                                  if (status == 'occupied')
                                    'occupiedSlots': FieldValue.increment(1),
                                  if (status == 'reserved')
                                    'reservedSlots': FieldValue.increment(1),
                                });

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Slot added successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error adding slot: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => isChecking = false);
                            }
                          }
                        }
                      },
                child: isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add Slot'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteSlot(ParkingSlotModel slot, String mallId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Slot'),
        content: Text(
          'Are you sure you want to delete slot ${slot.slotNumber}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Check if there are any active bookings for this slot
      final bookingQuery = await FirebaseFirestore.instance
          .collection('malls')
          .doc(mallId)
          .collection('activeBookings')
          .where('slotId', isEqualTo: slot.slotId)
          .get();

      if (bookingQuery.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot delete slot with active bookings'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // If no active bookings, proceed with deletion
      await FirebaseFirestore.instance
          .collection('malls')
          .doc(mallId)
          .collection('slots')
          .doc(slot.slotId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting slot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditSlotDialog(
    BuildContext context,
    ParkingSlotModel slot,
  ) async {
    final formKey = GlobalKey<FormState>();
    final slotNumberController = TextEditingController(
      text: slot.slotNumber.toString(),
    );
    final floorController = TextEditingController(text: slot.floor ?? '');
    final zoneController = TextEditingController(text: slot.zone ?? '');
    String status = slot.status.toLowerCase();
    String fuelType = slot.fuelType;
    String? categoryRestriction = slot.categoryRestriction;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Parking Slot'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: slotNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Slot Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required field' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: floorController,
                  decoration: const InputDecoration(
                    labelText: 'Floor (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: zoneController,
                  decoration: const InputDecoration(
                    labelText: 'Zone (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: fuelType,
                  decoration: const InputDecoration(
                    labelText: 'Fuel Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'petrol', child: Text('Petrol')),
                    DropdownMenuItem(
                      value: 'ev',
                      child: Text('Electric Vehicle'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      fuelType = value;
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'available',
                      child: Text('Available'),
                    ),
                    DropdownMenuItem(
                      value: 'occupied',
                      child: Text('Occupied'),
                    ),
                    DropdownMenuItem(
                      value: 'reserved',
                      child: Text('Reserved'),
                    ),
                    DropdownMenuItem(
                      value: 'maintenance',
                      child: Text('Maintenance'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      status = value;
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: categoryRestriction,
                  decoration: const InputDecoration(
                    labelText: 'Category Restriction (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('No Restriction'),
                    ),
                    ...['Compact', 'Standard', 'Large', 'Handicap'].map((
                      category,
                    ) {
                      return DropdownMenuItem(
                        value: category.toLowerCase(),
                        child: Text(category),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    categoryRestriction = value;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  await FirebaseFirestore.instance
                      .collection('malls')
                      .doc(_selectedMallId!)
                      .collection('slots')
                      .doc(slot.slotId)
                      .update({
                        'slotNumber':
                            int.tryParse(slotNumberController.text.trim()) ?? 0,
                        'floor': floorController.text.trim().isNotEmpty
                            ? floorController.text.trim()
                            : null,
                        'zone': zoneController.text.trim().isNotEmpty
                            ? zoneController.text.trim()
                            : null,
                        'fuelType': fuelType,
                        'categoryRestriction': categoryRestriction,
                        'status': status,
                        'lastUpdated': FieldValue.serverTimestamp(),
                      });

                  if (mounted) {
                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Slot updated successfully'),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  print(e);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating slot: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
