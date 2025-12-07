import 'package:cloud_firestore/cloud_firestore.dart';

class MallModel {
  final String mallId;
  final String name;
  final String address;
  final int totalSlots;
  final int petrolSlots;
  final int evSlots;
  final int availableSlots;
  final int occupiedSlots;
  final int reservedSlots;
  final Map<String, int> categoryDistribution;
  final bool isActive;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final DateTime createdAt;

  MallModel({
    required this.mallId,
    required this.name,
    required this.address,
    required this.totalSlots,
    required this.petrolSlots,
    required this.evSlots,
    required this.availableSlots,
    required this.occupiedSlots,
    required this.reservedSlots,
    required this.categoryDistribution,
    required this.isActive,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    required this.createdAt,
  });

  factory MallModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      // Safely parse location
      double lat = 0.0;
      double lng = 0.0;
      final location = data['location'];

      if (location is Map<String, dynamic>) {
        lat = (location['latitude'] as num?)?.toDouble() ?? 0.0;
        lng = (location['longitude'] as num?)?.toDouble() ?? 0.0;
      } else if (location is GeoPoint) {
        lat = location.latitude;
        lng = location.longitude;
      }

      return MallModel(
        mallId: doc.id,
        name: data['name'] ?? '',
        address: data['address'] ?? '',
        totalSlots: (data['totalSlots'] as num?)?.toInt() ?? 0,
        petrolSlots: (data['petrolSlots'] as num?)?.toInt() ?? 0,
        evSlots: (data['evSlots'] as num?)?.toInt() ?? 0,
        availableSlots: (data['availableSlots'] as num?)?.toInt() ?? 0,
        occupiedSlots: (data['occupiedSlots'] as num?)?.toInt() ?? 0,
        reservedSlots: (data['reservedSlots'] as num?)?.toInt() ?? 0,
        categoryDistribution: Map<String, int>.from(
          data['categoryDistribution'] ?? {},
        ),
        isActive: data['isActive'] ?? true,
        latitude: lat,
        longitude: lng,
        imageUrl: data['imageUrl'],
        createdAt: data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } catch (e, stack) {
      print('Error parsing MallModel for doc ${doc.id}: $e');
      print('Data: ${doc.data()}');
      print(stack);
      // Return a dummy/safe model instead of crashing
      return MallModel(
        mallId: doc.id,
        name: 'Error Loading Mall',
        address: 'Error',
        totalSlots: 0,
        petrolSlots: 0,
        evSlots: 0,
        availableSlots: 0,
        occupiedSlots: 0,
        reservedSlots: 0,
        categoryDistribution: {},
        isActive: false,
        latitude: 0,
        longitude: 0,
        createdAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'totalSlots': totalSlots,
      'petrolSlots': petrolSlots,
      'evSlots': evSlots,
      'availableSlots': availableSlots,
      'occupiedSlots': occupiedSlots,
      'reservedSlots': reservedSlots,
      'categoryDistribution': categoryDistribution,
      'isActive': isActive,
      'location': {'latitude': latitude, 'longitude': longitude},
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
