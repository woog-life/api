import 'package:sane_uuid/uuid.dart';

class LakeNotFoundException implements Exception {
  final Uuid lakeId;

  LakeNotFoundException(this.lakeId);

  @override
  String toString() {
    return 'Lake not found: $lakeId';
  }
}
