import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/repository/booking.dart';
import 'package:woog_api/src/domain/model/event.dart';

@injectable
class GetEvents {
  final BookingRepository _repo;

  GetEvents(this._repo);

  Future<List<Event>> call(Uuid lakeId) async {
    final now = DateTime.now();

    final events = await _repo.getAvailableEvents(lakeId, now);
    return events;
  }
}
