import 'package:meta/meta.dart';

@immutable
class LakeData {
  final DateTime time;
  final double temperature;

  const LakeData({
    required this.time,
    required this.temperature,
  });
}
