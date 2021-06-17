import 'package:meta/meta.dart';
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
  Future<LakeData?> getLakeData(String lakeId);

  Future<void> updateData(String lakeId, LakeData data);

  Future<NearDataDto> getNearestData(String lakeId, DateTime time);
}
