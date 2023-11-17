import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:woog_api/src/application/algo/interpolation.dart';
import 'package:woog_api/src/application/exception/not_found.dart';
import 'package:woog_api/src/application/model/lake_data.dart';
import 'package:woog_api/src/application/repository/unit_of_work.dart';

@injectable
final class GetTemperature {
  final UnitOfWorkProvider _uowProvider;

  GetTemperature(this._uowProvider);

  Future<LocalizedLakeData?> call(
    Uuid lakeId, {
    DateTime? time,
  }) async {
    return await _uowProvider.withUnitOfWork((uow) async {
      final lake = await uow.lakeRepo.getLake(lakeId);
      if (lake == null) {
        throw LakeNotFoundException(lakeId);
      }

      final location = tz.getLocation(lake.timeZoneId);

      var effectiveTime = time;
      if (effectiveTime == null) {
        final result = await uow.temperatureRepo.getLakeData(lakeId);
        return result?.localize(location);
      }

      if (!effectiveTime.isUtc) {
        effectiveTime = effectiveTime.toUtc();
      }

      final result = await _interpolateData(uow, lakeId, effectiveTime);
      return result?.localize(location);
    });
  }

  Future<LakeData?> _interpolateData(
    UnitOfWork uow,
    Uuid lakeId,
    DateTime time,
  ) async {
    final nearestData = await uow.temperatureRepo.getNearestData(lakeId, time);
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
