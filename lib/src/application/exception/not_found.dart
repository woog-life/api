import 'package:meta/meta.dart';
import 'package:sane_uuid/uuid.dart';

@immutable
final class NotFoundException implements Exception {
  final String id;
  final String message;

  const NotFoundException(this.id, this.message);

  @override
  String toString() {
    return '$message: $id';
  }
}

@immutable
final class LakeNotFoundException extends NotFoundException {
  LakeNotFoundException(Uuid lakeId)
      : super(
          lakeId.toString(),
          'Lake not found',
        );
}
