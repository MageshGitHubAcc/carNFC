class ParkingFailure implements Exception {
  const ParkingFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
