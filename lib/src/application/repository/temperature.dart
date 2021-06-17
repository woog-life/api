import 'package:meta/meta.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/domain/model/lake_data.dart';

@immutable
class NearDataDto {
  final LakeData? before;
  final LakeData? after;

  const NearDataDto({
    required this.before,
    required this.after,
  });
}

abstract class TemperatureRepository {
  Future<LakeData?> getLakeData(Uuid lakeId);

  Future<void> updateData(Uuid lakeId, LakeData data);

  Future<NearDataDto> getNearestData(Uuid lakeId, DateTime time);
}
