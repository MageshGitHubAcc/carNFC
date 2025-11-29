import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/data/models/mall_model.dart';
import 'package:flutter_app/data/models/parking_slot_model.dart';
import 'package:flutter_app/data/providers/provider.dart';
import 'vehicle_details_screen.dart';

class SlotSelectionScreen extends ConsumerStatefulWidget {
  const SlotSelectionScreen({super.key, required this.mall});

  static const routeName = '/slot-selection';

  final MallModel mall;

  @override
  ConsumerState<SlotSelectionScreen> createState() =>
      _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends ConsumerState<SlotSelectionScreen> {
  String _selectedFuelType = 'All'; // Default to show all slots

  // List of fuel type categories
  final List<String> fuelTypes = ['All', 'Petrol', 'Diesel', 'EV', 'CNG'];

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(mallSlotsProvider(widget.mall.mallId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Select a Slot - ${widget.mall.name}'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fuel Type Filter Chips
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fuelTypes.length,
                itemBuilder: (context, index) {
                  final type = fuelTypes[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(type),
                      selected: _selectedFuelType == type,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFuelType = selected ? type : 'All';
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: _selectedFuelType == type
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                        fontWeight: _selectedFuelType == type
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 8),

            // Slots Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: slotsAsync.when(
                  data: (slots) {
                    // Filter slots by selected fuel type
                    final filteredSlots = _selectedFuelType == 'All'
                        ? slots
                        : slots
                              .where(
                                (slot) =>
                                    slot.fuelType?.toLowerCase() ==
                                    _selectedFuelType.toLowerCase(),
                              )
                              .toList();

                    if (filteredSlots.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No ${_selectedFuelType == 'All' ? '' : '$_selectedFuelType '}slots available',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.8,
                          ),
                      itemCount: filteredSlots.length,
                      itemBuilder: (context, index) {
                        final slot = filteredSlots[index];
                        return _buildSlotCard(slot);
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error loading slots: $error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotCard(ParkingSlotModel slot) {
    final isAvailable = slot.status == 'available';

    return Card(
      margin: const EdgeInsets.all(4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide.none,
      ),
      child: InkWell(
        // In the _buildSlotCard method's onTap:
        onTap: isAvailable
            ? () {
                Navigator.of(context).pushNamed(
                  VehicleDetailsScreen.routeName,
                  arguments: VehicleDetailsArgs(mall: widget.mall, slot: slot),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Fuel type icon
              Icon(
                _getFuelTypeIcon(slot.fuelType),
                size: 28,
                color: isAvailable
                    ? _getFuelTypeColor(slot.fuelType)
                    : Colors.grey[400],
              ),
              // Slot number
              Text(
                'P${slot.slotNumber.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isAvailable ? Colors.black87 : Colors.grey[400],
                ),
              ),
              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isAvailable ? 'Available' : 'Booked',
                  style: TextStyle(
                    fontSize: 10,
                    color: isAvailable ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (slot.fuelType != null) ...[
                const SizedBox(height: 2),
                Text(
                  slot.fuelType!,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for fuel type UI
  IconData _getFuelTypeIcon(String? fuelType) {
    switch (fuelType?.toLowerCase()) {
      case 'petrol':
        return Icons.local_gas_station;
      case 'diesel':
        return Icons.local_gas_station_outlined;
      case 'ev':
      case 'electric':
        return Icons.electric_car;
      case 'cng':
        return Icons.gas_meter;
      default:
        return Icons.directions_car;
    }
  }

  Color _getFuelTypeColor(String? fuelType) {
    switch (fuelType?.toLowerCase()) {
      case 'petrol':
        return Colors.orange;
      case 'diesel':
        return Colors.blueGrey;
      case 'ev':
      case 'electric':
        return Colors.blue;
      case 'cng':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
