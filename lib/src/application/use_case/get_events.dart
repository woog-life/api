import 'package:injectable/injectable.dart';
import 'package:woog_api/src/domain/model/event.dart';

@injectable
class GetEvents {
  Future<List<Event>> call(String lakeId) async {
    // TODO: implement
    return [
      Event(
        variation: "Badestelle Familienbad",
        bookingLink: "https://ztix.de/hp/events/3834/info",
        beginTime: DateTime.now().toUtc(),
        endTime: DateTime.now().toUtc().add(Duration(hours: 5)),
        saleStartTime: DateTime.now().toUtc(),
        isAvailable: true,
      )
    ];
  }
}
