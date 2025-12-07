import 'package:flutter_app/data/models/parking_session_model.dart';
import 'package:flutter_app/data/models/parking_slot_model.dart';

abstract class ParkingRepository {
  Future<List<ParkingSlotModel>> fetchSlots();
  Future<List<ParkingSessionModel>> fetchSessions();
  Future<void> saveSlot(ParkingSlotModel slot);
  Future<void> saveSession(ParkingSessionModel session);
}
