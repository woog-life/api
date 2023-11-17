import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/exception/not_found.dart';
import 'package:woog_api/src/application/model/tidal_extremum_data.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:woog_api/src/application/repository/unit_of_work.dart';

@injectable
final class GetTidalExtrema {
  final UnitOfWorkProvider _uowProvider;

  GetTidalExtrema(this._uowProvider);

  Future<List<LocalizedTidalExtremumData>> call({
    required Uuid lakeId,
    required DateTime? time,
    required int? upcomingLimit,
  }) async {
    return await _uowProvider.withUnitOfWork((uow) async {
      final lake = await uow.lakeRepo.getLake(lakeId);
      if (lake == null) {
        throw LakeNotFoundException(lakeId);
      }

      final location = tz.getLocation(lake.timeZoneId);

      var effectiveTime = time;
      if (effectiveTime == null) {
        effectiveTime = DateTime.now().toUtc();
      } else if (!effectiveTime.isUtc) {
        effectiveTime = effectiveTime.toUtc();
      }

      final lastExtremum = await uow.tidesRepo.getLastTidalExtremum(
        lakeId: lakeId,
        time: effectiveTime,
      );

      final nextExtrema = await uow.tidesRepo.getTidalExtremaAfter(
        lakeId: lakeId,
        time: effectiveTime,
        limit: upcomingLimit ?? 4,
      );

      return [
        if (lastExtremum != null) lastExtremum.localize(location),
        for (final nextExtremum in nextExtrema) nextExtremum.localize(location),
      ];
    });
  }
}
