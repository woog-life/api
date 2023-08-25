import 'package:meta/meta.dart';

@immutable
final class TidalExtremumData {
  final bool isHighTide;
  final DateTime time;
  final double height;

  TidalExtremumData({
    required this.isHighTide,
    required this.time,
    required this.height,
  });
}
