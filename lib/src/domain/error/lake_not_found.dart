import 'package:sane_uuid/uuid.dart';

class LakeNotFoundError implements Exception {
  final Uuid lakeId;

  LakeNotFoundError(this.lakeId);

  @override
  String toString() {
    return 'Lake not found: $lakeId';
  }
}
