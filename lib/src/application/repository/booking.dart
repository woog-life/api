import 'package:woog_api/src/domain/model/event.dart';

abstract class BookingRepository {
  Future<void> updateEvents(
    String lakeId,
    List<Event> events,
  );

  Future<List<Event>> getAvailableEvents(String lakeId, DateTime endsAfter);
}
