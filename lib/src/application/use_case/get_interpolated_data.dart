import 'package:injectable/injectable.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/domain/error/time.dart';
import 'package:woog_api/src/domain/model/lake_data.dart';

@injectable
class GetInterpolatedData {
  final LakeRepository _repo;

  GetInterpolatedData(this._repo);

  Future<LakeData?> call(String lakeId, DateTime time) async {
    if(!time.isUtc) {
      throw NonUtcTimeError(time);
    }

    final nearestData = await _repo.getNearestData(lakeId, time);
    final before = nearestData.before;
    final after = nearestData.after;

    if (before != null && after != null) {
      return _interpolate(before: before, after: after, target: time);
    } else if (before != null && after == null) {
      return before;
    } else if (before == null && after != null) {
      return after;
    } else {
      return null;
    }
  }

  LakeData _interpolate({
    required LakeData before,
    required LakeData after,
    required DateTime target,
  }) {
    final actualTimeDiff = after.time.difference(before.time).inMilliseconds;
    final targetTimeDiff = target.difference(before.time).inMilliseconds;

    if (actualTimeDiff == 0 || targetTimeDiff == 0) {
      return before;
    }

    final scalingFactor = targetTimeDiff / actualTimeDiff;
    final actualTemperatureDiff = after.temperature - before.temperature;

    final interpolatedValue =
        before.temperature + scalingFactor * actualTemperatureDiff;

    return LakeData(time: target, temperature: interpolatedValue);
  }
}
