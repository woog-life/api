import 'package:meta/meta.dart';

@immutable
final class TimeValue {
  final DateTime time;
  final double value;

  const TimeValue(this.time, this.value);
}

TimeValue interpolate({
  required TimeValue before,
  required TimeValue after,
  required DateTime targetTime,
}) {
  final actualTimeDiff = after.time.difference(before.time).inMilliseconds;
  final targetTimeDiff = targetTime.difference(before.time).inMilliseconds;

  if (actualTimeDiff == 0 || targetTimeDiff == 0) {
    return before;
  }

  final scalingFactor = targetTimeDiff / actualTimeDiff;
  final actualTemperatureDiff = after.value - before.value;

  final interpolatedValue =
      before.value + scalingFactor * actualTemperatureDiff;

  return TimeValue(targetTime, interpolatedValue);
}
