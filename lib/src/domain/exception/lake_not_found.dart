import 'package:meta/meta.dart';
import 'package:sane_uuid/uuid.dart';

@immutable
final class LakeNotFoundException implements Exception {
  final Uuid lakeId;

  LakeNotFoundException(this.lakeId);

  @override
  String toString() {
    return 'Lake not found: $lakeId';
  }
}
