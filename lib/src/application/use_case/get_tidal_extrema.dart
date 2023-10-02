import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/exception/time.dart';
import 'package:woog_api/src/application/model/tidal_extremum_data.dart';
import 'package:woog_api/src/application/repository/tides.dart';

@injectable
final class GetTidalExtrema {
  final TidesRepository _repo;

  GetTidalExtrema(this._repo);

  Future<List<TidalExtremumData>> call({
    required Uuid lakeId,
    required DateTime? time,
    required int? upcomingLimit,
  }) async {
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
      if (lastExtremum != null) lastExtremum,
      ...nextExtrema,
    ];
  }
}
