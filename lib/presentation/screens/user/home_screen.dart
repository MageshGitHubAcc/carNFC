import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/presentation/screens/user/recent_booking_screen.dart';
import 'package:flutter_app/presentation/screens/user/slot_selection_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/mall_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserDataProvider);
    final mallsAsync = ref.watch(allMallsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: userAsync.when(
          data: (user) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Smart Parking',
                style: TextStyle(
                  color: Color(0xFF2A7CF6),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                user == null
                    ? 'Welcome back'
                    : 'Hi, ${user.name.split(' ').first}',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
            ],
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const Text('Smart Parking'),
        ),
        actions: [
          // IconButton(
          //   onPressed: () {
          //     uploadAllDummyData();
          //   },
          //   icon: const Icon(Icons.person, color: Color(0xFF1C1F2E)),
          // ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF1C1F2E)),
            onPressed: () {
              ref.read(authRepositoryProvider).signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allMallsProvider);
          ref.invalidate(userParkingHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Parking',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // ✅ Existing Mall List
                mallsAsync.when(
                  data: (malls) {
                    if (malls.isEmpty) return const _EmptyState();
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: malls.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, index) {
                        final mall = malls[index];
                        return _MallCard(
                          mall: mall,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              SlotSelectionScreen.routeName,
                              arguments: mall,
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text("Error loading malls: $e")),
                ),

                const SizedBox(height: 20),

                // ✅ Inserted New Widgets
                const RecentBookingsWidget(),
                const SizedBox(height: 16),
                const ParkingHistoryWidget(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> uploadAllDummyData() async {
    await uploadDummyMall();
    await uploadDummyParkingSlots();
    await uploadDummyParkingHistory();
  }

  // ---------------------------------------------------------------------------
  // 1️⃣ CREATE DUMMY MALL
  Future<void> uploadDummyMall() async {
    final mallRef = FirebaseFirestore.instance
        .collection("malls")
        .doc("mall_a");

    await mallRef.set({
      "name": "ABC Mall",
      "address": "123 Main Street, Chennai",
      "totalSlots": 100,
      "petrolSlots": 60,
      "evSlots": 40,
      "availableSlots": 80,
      "occupiedSlots": 20,
      "categoryDistribution": {
        "hatchback": 20,
        "sedan": 30,
        "suv": 30,
        "convertible": 10,
        "pickupTruck": 10,
      },
      "isActive": true,
      "location": {"latitude": 13.0827, "longitude": 80.2707},
      "imageUrl": "https://example.com/mall.jpg",
      "createdAt": FieldValue.serverTimestamp(),
    });

    print("🏬 Dummy Mall created: mall_a");
  }

  // ---------------------------------------------------------------------------
  // 2️⃣ CREATE DUMMY PARKING SLOTS
  Future<void> uploadDummyParkingSlots() async {
    final firestore = FirebaseFirestore.instance;
    final slotsCollection = firestore
        .collection("malls")
        .doc("mall_a")
        .collection("slots");
    final now = DateTime.now();

    for (int i = 1; i <= 20; i++) {
      final slotId = "slot_$i";

      await slotsCollection.doc(slotId).set({
        "slotNumber": i,
        "fuelType": i % 4 == 0 ? "ev" : "petrol",
        "categoryRestriction": i % 5 == 0 ? "sedan" : null,
        "status": "available",
        "floor": "B1",
        "zone": i <= 10 ? "A" : "B",
        "currentBookingId": null,
        "currentUserId": null,
        "lastUpdated": Timestamp.fromDate(now),
      });

      print("🅿️ Added slot: $slotId");
    }

    print("🚗 20 dummy parking slots uploaded.");
  }

  // ---------------------------------------------------------------------------
  // 3️⃣ CREATE DUMMY PARKING HISTORY FOR CURRENT USER
  Future<void> uploadDummyParkingHistory() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("❌ No logged-in user. Cannot create parking history.");
      return;
    }

    final historyId = "sample_booking";
    final checkIn = DateTime.now().subtract(const Duration(hours: 3));
    final checkOut = checkIn.add(const Duration(hours: 2, minutes: 30));

    // User sub-collection
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("parkingHistory")
        .doc(historyId)
        .set({
          "mallId": "mall_a",
          "mallName": "ABC Mall",
          "slotId": "slot_15",
          "slotNumber": 15,
          "carNumber": "KA01AB1234",
          "carType": "Honda City",
          "vehicleCategory": "sedan",
          "checkInDateTime": Timestamp.fromDate(checkIn),
          "checkOutDateTime": Timestamp.fromDate(checkOut),
          "status": "completed",
          "duration": "2 hours 30 mins",
          "createdAt": FieldValue.serverTimestamp(),
        });

    // Global bookings collection
    await FirebaseFirestore.instance.collection("bookings").doc(historyId).set({
      "userId": user.uid,
      "userName": user.displayName ?? "Test User",
      "mallId": "mall_a",
      "mallName": "ABC Mall",
      "slotId": "slot_15",
      "slotNumber": 15,
      "carNumber": "KA01AB1234",
      "carType": "Honda City",
      "vehicleCategory": "sedan",
      "checkInDateTime": Timestamp.fromDate(checkIn),
      "checkOutDateTime": Timestamp.fromDate(checkOut),
      "status": "completed",
      "duration": "2 hours 30 mins",
      "encryptedData": "dummy_encrypted_string",
      "createdAt": FieldValue.serverTimestamp(),
    });

    print("📘 Parking history added for user: ${user.uid}");
  }
}

class _MallCard extends StatelessWidget {
  const _MallCard({required this.mall, required this.onTap});

  final MallModel mall;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A7CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_mall_outlined,
                    color: Color(0xFF2A7CF6),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mall.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1F2E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mall.address,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 12),
            const Text(
              'Parking Status',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatChip(
                  label: 'Available',
                  value: '${mall.availableSlots}',
                  color: const Color(0xFF22C55E),
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Occupied',
                  value: '${mall.occupiedSlots}',
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatChip(
                  label: 'Reserved',
                  value:
                      '${mall.totalSlots - mall.availableSlots - mall.occupiedSlots}',
                  color: const Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Total Slots',
                  value: '${mall.totalSlots}',
                  color: const Color(0xFF3B82F6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.9),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.location_off_outlined, size: 48, color: Color(0xFF9CA3AF)),
          SizedBox(height: 12),
          Text(
            'No malls available yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Please check back later or contact support',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
