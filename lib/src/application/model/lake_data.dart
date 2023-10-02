import 'package:meta/meta.dart';
import 'package:timezone/timezone.dart' as tz;

@immutable
final class LakeData {
  final DateTime time;
  final double temperature;

  const LakeData({
    required this.time,
    required this.temperature,
  });

  LocalizedLakeData localize(tz.Location location) {
    return LocalizedLakeData(
      time: time,
      temperature: temperature,
      localTime: tz.TZDateTime.from(time, location),
    );
  }
}

@immutable
final class LocalizedLakeData extends LakeData {
  final DateTime localTime;

  const LocalizedLakeData({
    required super.time,
    required super.temperature,
    required this.localTime,
  });
}
