import 'package:hive/hive.dart';

part 'parking_session_model.g.dart';

@HiveType(typeId: 1)
class ParkingSessionModel extends HiveObject {
  ParkingSessionModel({
    required this.id,
    required this.carNumber,
    required this.ownerName,
    required this.mobile,
    required this.slotId,
    required this.checkInTime,
    this.checkOutTime,
    this.amountPaid,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String carNumber;

  @HiveField(2)
  String ownerName;

  @HiveField(3)
  String mobile;

  @HiveField(4)
  String slotId;

  @HiveField(5)
  DateTime checkInTime;

  @HiveField(6)
  DateTime? checkOutTime;

  @HiveField(7)
  double? amountPaid;

  bool get isActive => checkOutTime == null;
}
