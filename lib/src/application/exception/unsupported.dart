import 'package:meta/meta.dart';
import 'package:woog_api/src/application/model/lake.dart';

@immutable
final class UnsupportedFeatureException implements Exception {
  final Feature feature;

  const UnsupportedFeatureException(this.feature);

  @override
  String toString() {
    return 'Required feature not supported: $feature';
  }
}
