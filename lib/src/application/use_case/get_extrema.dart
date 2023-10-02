import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:woog_api/src/application/exception/not_found.dart';
import 'package:woog_api/src/application/model/lake_data.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/application/repository/temperature.dart';

@injectable
final class GetExtrema {
  final LakeRepository _lakeRepo;
  final TemperatureRepository _repo;

  GetExtrema(this._lakeRepo, this._repo);

  Future<LakeDataExtrema<LocalizedLakeData>?> call(Uuid lakeId) async {
    final lake = await _lakeRepo.getLake(lakeId);
    if (lake == null) {
      throw LakeNotFoundException(lakeId);
    }

    final location = tz.getLocation(lake.timeZoneId);

    final result = await _repo.getExtrema(lakeId);
    return result?.localize(location);
  }
}
