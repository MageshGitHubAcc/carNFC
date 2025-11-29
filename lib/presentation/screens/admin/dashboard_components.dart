import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/global_booking_model.dart';
import 'package:flutter_app/data/models/parking_slot_model.dart';
import 'package:intl/intl.dart';

// -----------------------------------------------------------------------------
// STAT CARD
// -----------------------------------------------------------------------------

class StatCardData {
  const StatCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trend,
  });

  final String title;
  final String value;
  final String? subtitle;
  final String? trend; // e.g., "+5%"
  final IconData icon;
  final Color color;
}

class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({super.key, required this.data});

  final StatCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, color: data.color, size: 22),
              ),
              if (data.trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data.trend!,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.title,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (data.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  data.subtitle!,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SLOT TILE
// -----------------------------------------------------------------------------

class DashboardSlotTile extends StatelessWidget {
  const DashboardSlotTile({super.key, required this.slot, required this.onTap});

  final ParkingSlotModel slot;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (slot.status.toLowerCase()) {
      case 'available':
        return const Color(0xFF10B981); // Emerald 500
      case 'occupied':
        return const Color(0xFFEF4444); // Red 500
      case 'reserved':
        return const Color(0xFFF59E0B); // Amber 500
      case 'maintenance':
        return const Color(0xFF64748B); // Slate 500
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Color get _backgroundColor {
    return _statusColor.withOpacity(0.08);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _statusColor.withOpacity(0.3), width: 1),
          ),
          child: Stack(
            children: [
              // Slot Number
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'P${slot.slotNumber}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: _statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        slot.floor ?? 'G',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Status Indicator Dot
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// BOOKING ROW
// -----------------------------------------------------------------------------

class DashboardBookingCard extends StatelessWidget {
  const DashboardBookingCard({
    super.key,
    required this.booking,
    required this.onCheckout,
  });

  final GlobalBookingModel booking;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final duration = DateTime.now().difference(booking.checkInDateTime);
    final isLongDuration = duration.inHours > 3;
    final accentColor = isLongDuration
        ? const Color(0xFFF97316)
        : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Bar
              Container(width: 6, color: accentColor),
              // Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Car Number & Slot
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            booking.carNumber,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.local_parking,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${booking.slotNumber}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Body: User & Time
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.person_rounded,
                            booking.userName,
                            Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          _buildInfoChip(
                            Icons.access_time_filled_rounded,
                            'In: ${_formatTime(booking.checkInDateTime)}',
                            Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Footer: Duration & Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            booking.status == BookingStatus.reserved
                                ? 'Reserved ${_formatDuration(duration)} ago'
                                : 'Parked for ${_formatDuration(duration)}',
                            style: TextStyle(
                              color: isLongDuration
                                  ? const Color(0xFFF97316)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(
                            height: 36,
                            child: ElevatedButton.icon(
                              onPressed: onCheckout,
                              icon: Icon(
                                booking.status == BookingStatus.reserved
                                    ? Icons.edit_outlined
                                    : Icons.logout_rounded,
                                size: 16,
                              ),
                              label: Text(
                                booking.status == BookingStatus.reserved
                                    ? 'Edit'
                                    : 'Checkout',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    booking.status == BookingStatus.reserved
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

// -----------------------------------------------------------------------------
// LEGEND ITEM
// -----------------------------------------------------------------------------

class DashboardLegendItem extends StatelessWidget {
  const DashboardLegendItem({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
