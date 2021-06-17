import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:woog_api/src/application/repository/booking.dart';
import 'package:woog_api/src/domain/error/time.dart';
import 'package:woog_api/src/domain/model/event.dart';

@immutable
class UpdateEvent {
  final String bookingLink;
  final DateTime beginTime;
  final DateTime endTime;
  final DateTime saleStartTime;
  final bool isAvailable;

  const UpdateEvent({
    required this.bookingLink,
    required this.beginTime,
    required this.endTime,
    required this.saleStartTime,
    required this.isAvailable,
  });
}

@injectable
class UpdateEvents {
  final Logger _logger;
  final BookingRepository _repo;

  UpdateEvents(this._logger, this._repo);

  Future<void> call(
    String lakeId,
    String variation,
    List<UpdateEvent> events,
  ) async {
    _logger.d('Received ${events.length} events for lake $lakeId ($variation)');
    final modelEvents = <Event>[];

    for (final updateEvent in events) {
      for (final time in [
        updateEvent.beginTime,
        updateEvent.endTime,
        updateEvent.saleStartTime,
      ]) {
        if (!time.isUtc) {
          throw NonUtcTimeError(time);
        }
      }

      final event = Event(
        variation: variation,
        bookingLink: updateEvent.bookingLink,
        beginTime: updateEvent.beginTime,
        endTime: updateEvent.endTime,
        saleStartTime: updateEvent.saleStartTime,
        isAvailable: updateEvent.isAvailable,
      );
      modelEvents.add(event);
    }

    await _repo.updateEvents(lakeId, modelEvents);
  }
}
