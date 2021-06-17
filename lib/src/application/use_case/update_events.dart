import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/repository/booking.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/domain/error/lake_not_found.dart';
import 'package:woog_api/src/domain/error/time.dart';
import 'package:woog_api/src/domain/error/unsupported.dart';
import 'package:woog_api/src/domain/model/event.dart';
import 'package:woog_api/src/domain/model/lake.dart';

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
  final LakeRepository _lakeRepo;
  final BookingRepository _bookingRepo;

  UpdateEvents(
    this._logger,
    this._lakeRepo,
    this._bookingRepo,
  );

  Future<void> call(
    Uuid lakeId,
    String variation,
    List<UpdateEvent> events,
  ) async {
    _logger.d('Received ${events.length} events for lake $lakeId ($variation)');

    final lake = await _lakeRepo.getLake(lakeId);
    if (lake == null) {
      throw LakeNotFoundError(lakeId);
    }

    if (!lake.features.contains(Feature.booking)) {
      throw const UnsupportedFeatureException(Feature.booking);
    }

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

    await _bookingRepo.updateEvents(lakeId, modelEvents);
  }
}
