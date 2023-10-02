import 'package:meta/meta.dart';
import 'package:timezone/timezone.dart' as tz;

@immutable
final class TidalExtremumData implements Comparable<TidalExtremumData> {
  final bool isHighTide;
  final DateTime time;
  final String height;

  TidalExtremumData({
    required this.isHighTide,
    required this.time,
    required this.height,
  });

  @override
  int compareTo(TidalExtremumData other) {
    return time.compareTo(other.time);
  }

  LocalizedTidalExtremumData localize(tz.Location location) {
    return LocalizedTidalExtremumData(
      isHighTide: isHighTide,
      time: time,
      localTime: tz.TZDateTime.from(time, location),
      height: height,
    );
  }
}

@immutable
final class LocalizedTidalExtremumData extends TidalExtremumData {
  final DateTime localTime;

  LocalizedTidalExtremumData({
    required super.isHighTide,
    required super.time,
    required this.localTime,
    required super.height,
  });
}
