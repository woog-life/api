abstract class TimeError implements Exception {}

class FutureTimeError implements TimeError {
  final DateTime futureTime;

  FutureTimeError(this.futureTime);

  @override
  String toString() {
    return 'Invalid time received (from the future): $futureTime';
  }
}

class NonUtcTimeError implements TimeError {
  final DateTime nonUtcTime;

  NonUtcTimeError(this.nonUtcTime);

  @override
  String toString() {
    return 'Invalid time received (not UTC): $nonUtcTime';
  }
}
