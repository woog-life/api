class FutureTimeError implements Exception {
  final DateTime futureTime;

  FutureTimeError(this.futureTime);

  @override
  String toString() {
    return 'Invalid time received (from the future): $futureTime';
  }
}
