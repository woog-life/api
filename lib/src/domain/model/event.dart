import 'package:meta/meta.dart';

@immutable
class Event {
  final String variation;
  final String bookingLink;
  final DateTime beginTime;
  final DateTime endTime;
  final DateTime saleStartTime;
  final bool isAvailable;

  const Event({
    required this.variation,
    required this.bookingLink,
    required this.beginTime,
    required this.endTime,
    required this.saleStartTime,
    required this.isAvailable,
  });
}
