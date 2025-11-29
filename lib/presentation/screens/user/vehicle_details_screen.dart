import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/mall_model.dart';
import '../../../data/models/parking_slot_model.dart';
import '../../../data/providers/provider.dart';
import 'booking_confirmation_screen.dart';

class VehicleDetailsArgs {
  VehicleDetailsArgs({required this.mall, required this.slot});

  final MallModel mall;
  final ParkingSlotModel slot;
}

class VehicleDetailsScreen extends ConsumerStatefulWidget {
  const VehicleDetailsScreen({
    super.key,
    required this.mall,
    required this.slot,
  });

  static const routeName = '/vehicle-details';

  final MallModel mall;
  final ParkingSlotModel slot;

  @override
  ConsumerState<VehicleDetailsScreen> createState() =>
      _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends ConsumerState<VehicleDetailsScreen> {
  final _carNumberController = TextEditingController();
  final _carTypeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _vehicleCategory = 'sedan';

  @override
  void dispose() {
    _carNumberController.dispose();
    _carTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Vehicle details'),
        backgroundColor: const Color(0xFFF4F6FB),
        elevation: 0,
        foregroundColor: const Color(0xFF111D33),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SlotSummaryCard(slot: widget.slot, mall: widget.mall),
                const SizedBox(height: 24),
                userAsync.when(
                  data: (user) =>
                      _UserHint(name: user?.name, email: user?.email),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                _buildLabel('Car number'),
                const SizedBox(height: 8),
                _buildField(
                  controller: _carNumberController,
                  hintText: 'TN 09 AB 1234',
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter car number'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildLabel('Car model'),
                const SizedBox(height: 8),
                _buildField(
                  controller: _carTypeController,
                  hintText: 'Tesla Model 3',
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter car model'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildLabel('Vehicle category'),
                const SizedBox(height: 8),
                _buildCategoryDropdown(),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A7CF6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _handleContinue,
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hintText,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = <String>['hatchback', 'sedan', 'suv'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<String>(
        value: _vehicleCategory,
        decoration: const InputDecoration(border: InputBorder.none),
        items: categories
            .map(
              (category) => DropdownMenuItem(
                value: category,
                child: Text(category[0].toUpperCase() + category.substring(1)),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _vehicleCategory = value);
          }
        },
      ),
    );
  }

  void _handleContinue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.pushNamed(
      context,
      BookingConfirmationScreen.routeName,
      arguments: BookingConfirmationArgs(
        mall: widget.mall,
        slot: widget.slot,
        carNumber: _carNumberController.text.trim(),
        carType: _carTypeController.text.trim(),
        vehicleCategory: _vehicleCategory,
      ),
    );
  }
}

class _SlotSummaryCard extends StatelessWidget {
  const _SlotSummaryCard({required this.slot, required this.mall});

  final ParkingSlotModel slot;
  final MallModel mall;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F1C2D4B),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mall.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1F2E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Chip(label: 'Spot', value: 'P ${slot.slotNumber}'),
              const SizedBox(width: 12),
              _Chip(label: 'Level', value: slot.floor ?? 'Level 1'),
              const SizedBox(width: 12),
              _Chip(label: 'Zone', value: slot.zone ?? 'A'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6FB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1F2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserHint extends StatelessWidget {
  const _UserHint({this.name, this.email});

  final String? name;
  final String? email;

  @override
  Widget build(BuildContext context) {
    if (name == null && email == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: Color(0xFF0EA5E9)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name != null)
                  Text(
                    name!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                if (email != null)
                  Text(
                    email!,
                    style: const TextStyle(color: Color(0xFF0F172A)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
