import 'package:meta/meta.dart';
import 'package:woog_api/src/domain/model/lake.dart';

@immutable
class UnsupportedFeatureException implements Exception {
  final Feature feature;

  const UnsupportedFeatureException(this.feature);

  @override
  String toString() {
    return 'Required feature not supported: $feature';
  }
}
