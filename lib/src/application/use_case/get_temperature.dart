import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/exception/not_found.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/application/repository/temperature.dart';
import 'package:woog_api/src/application/algo/interpolation.dart';
import 'package:woog_api/src/application/exception/time.dart';
import 'package:woog_api/src/application/model/lake_data.dart';
import 'package:timezone/timezone.dart' as tz;

@injectable
final class GetTemperature {
  final LakeRepository _lakeRepo;
  final TemperatureRepository _repo;

  GetTemperature(this._lakeRepo, this._repo);

  Future<LocalizedLakeData?> call(
    Uuid lakeId, {
    DateTime? time,
  }) async {
    final lake = await _lakeRepo.getLake(lakeId);
    if (lake == null) {
      throw LakeNotFoundException(lakeId);
    }

    final location = tz.getLocation(lake.timeZoneId);

    if (time == null) {
      final result = await _repo.getLakeData(lakeId);
      return result?.localize(location);
    }

    if (!time.isUtc) {
      time = time.toUtc();
    }

    final result = await _interpolateData(lakeId, time);
    return result?.localize(location);
  }

  Future<LakeData?> _interpolateData(Uuid lakeId, DateTime time) async {
    final nearestData = await _repo.getNearestData(lakeId, time);
    final before = nearestData.before;
    final after = nearestData.after;

    if (before != null && after != null) {
      final result = interpolate(
        before: TimeValue(before.time, before.temperature),
        after: TimeValue(after.time, after.temperature),
        targetTime: time,
      );
      return LakeData(
        time: result.time,
        temperature: result.value,
      );
    } else if (before != null && after == null) {
      return before;
    } else if (before == null && after != null) {
      return after;
    } else {
      return null;
    }
  }
}
