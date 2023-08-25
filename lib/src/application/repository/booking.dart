import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/model/event.dart';

abstract interface class BookingRepository {
  Future<void> updateEvents(
    Uuid lakeId,
    List<Event> events,
  );

  Future<List<Event>> getAvailableEvents(Uuid lakeId, DateTime endsAfter);
}
