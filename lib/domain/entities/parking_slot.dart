class ParkingSlot {
  ParkingSlot({
    required this.id,
    required this.zone,
    required this.number,
    this.isOccupied = false,
  });

  final String id;
  final String zone;
  final int number;
  final bool isOccupied;

  ParkingSlot copyWith({bool? isOccupied}) {
    return ParkingSlot(
      id: id,
      zone: zone,
      number: number,
      isOccupied: isOccupied ?? this.isOccupied,
    );
  }
}
