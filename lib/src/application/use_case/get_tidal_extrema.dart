import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/exception/not_found.dart';
import 'package:woog_api/src/application/model/tidal_extremum_data.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/application/repository/tides.dart';
import 'package:timezone/timezone.dart' as tz;

@injectable
final class GetTidalExtrema {
  final LakeRepository _lakeRepo;
  final TidesRepository _repo;

  GetTidalExtrema(this._lakeRepo, this._repo);

  Future<List<LocalizedTidalExtremumData>> call({
    required Uuid lakeId,
    required DateTime? time,
    required int? upcomingLimit,
  }) async {
    final lake = await _lakeRepo.getLake(lakeId);
    if (lake == null) {
      throw LakeNotFoundException(lakeId);
    }

    final location = tz.getLocation(lake.timeZoneId);

    if (time == null) {
      time = DateTime.now().toUtc();
    } else if (!time.isUtc) {
      time = time.toUtc();
    }

    final lastExtremum = await _repo.getLastTidalExtremum(
      lakeId: lakeId,
      time: time,
    );

    final nextExtrema = await _repo.getTidalExtremaAfter(
      lakeId: lakeId,
      time: time,
      limit: upcomingLimit ?? 4,
    );

    return [
      if (lastExtremum != null) lastExtremum.localize(location),
      for (final nextExtremum in nextExtrema) nextExtremum.localize(location),
    ];
  }
}
