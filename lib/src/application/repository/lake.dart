import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/repository/temperature.dart' as temp;
import 'package:woog_api/src/application/model/lake.dart';

@Deprecated('Use temperature.NearDataDto')
typedef NearDataDto = temp.NearDataDto;

abstract interface class LakeRepository {
  Future<Set<Lake>> getLakes();

  Future<Lake?> getLake(Uuid lakeId);
}
