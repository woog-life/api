import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/repository/temperature.dart';
import 'package:woog_api/src/domain/algo/interpolation.dart';
import 'package:woog_api/src/domain/exception/time.dart';
import 'package:woog_api/src/domain/model/lake_data.dart';

@injectable
final class GetTemperature {
  final TemperatureRepository _repo;

  GetTemperature(this._repo);

  Future<LakeData?> call(
    Uuid lakeId, {
    DateTime? time,
  }) async {
    if (time == null) {
      return _repo.getLakeData(lakeId);
    }
    if (!time.isUtc) {
      throw NonUtcTimeException(time);
    }

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
