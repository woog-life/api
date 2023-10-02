import 'package:meta/meta.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:timezone/timezone.dart' as tz;
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
final class LakeDataExtrema<LD extends LakeData> {
  final LD min;
  final LD max;

  const LakeDataExtrema({
    required this.min,
    required this.max,
  });

  LakeDataExtrema<LocalizedLakeData> localize(tz.Location location) {
    return LakeDataExtrema(
      min: min.localize(location),
      max: max.localize(location),
    );
  }
}

abstract interface class TemperatureRepository {
  Future<LakeData?> getLakeData(Uuid lakeId);

  Future<void> updateData(Uuid lakeId, LakeData data);

  Future<NearDataDto> getNearestData(Uuid lakeId, DateTime time);

  Future<LakeDataExtrema?> getExtrema(Uuid lakeId);
}
