import 'package:meta/meta.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/model/lake_data.dart';

@immutable
final class NearDataDto {
  final LakeData? before;
  final LakeData? after;

  const NearDataDto({
    required this.before,
    required this.after,
  });
}

@immutable
final class LakeDataExtrema {
  final LakeData min;
  final LakeData max;

  const LakeDataExtrema({
    required this.min,
    required this.max,
  });
}

abstract interface class TemperatureRepository {
  Future<LakeData?> getLakeData(Uuid lakeId);

  Future<void> updateData(Uuid lakeId, LakeData data);

  Future<NearDataDto> getNearestData(Uuid lakeId, DateTime time);

  Future<LakeDataExtrema?> getExtrema(Uuid lakeId);
}
