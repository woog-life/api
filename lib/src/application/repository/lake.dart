import 'package:woog_api/src/application/repository/temperature.dart' as temp;
import 'package:woog_api/src/domain/model/lake.dart';

@Deprecated('Use temperature.NearDataDto')
typedef NearDataDto = temp.NearDataDto;

abstract class LakeRepository {
  Future<Set<Lake>> getLakes();

  Future<Lake?> getLake(String lakeId);
}
