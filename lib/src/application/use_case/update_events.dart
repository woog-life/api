import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';

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

  UpdateEvents(this._logger);

  Future<void> call(
    String lakeId,
    String variation,
    List<UpdateEvent> events,
  ) async {
    _logger.i(
      'Received an ignored ${events.length} events for variation $variation',
    );
  }
}
