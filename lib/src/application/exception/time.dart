import 'package:meta/meta.dart';

abstract class TimeException implements Exception {}

@immutable
final class FutureTimeException implements TimeException {
  final DateTime futureTime;

  FutureTimeException(this.futureTime);

  @override
  String toString() {
    return 'Invalid time received (from the future): $futureTime';
  }
}

@immutable
final class NonUtcTimeException implements TimeException {
  final DateTime nonUtcTime;

  NonUtcTimeException(this.nonUtcTime);

  @override
  String toString() {
    return 'Invalid time received (not UTC): $nonUtcTime';
  }
}
