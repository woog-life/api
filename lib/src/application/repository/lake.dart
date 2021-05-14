import 'package:woog_api/src/domain/model/lake.dart';
import 'package:woog_api/src/domain/model/lake_data.dart';

abstract class LakeRepository {
  Future<Set<Lake>> getLakes();

  Future<Lake?> getLake(String lakeId);

  Future<void> updateData(String lakeId, LakeData data);
}
