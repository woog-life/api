import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:woog_api/src/application/exception/not_found.dart';
import 'package:woog_api/src/application/model/lake_data.dart';
import 'package:woog_api/src/application/repository/temperature.dart';
import 'package:woog_api/src/application/repository/unit_of_work.dart';

@injectable
final class GetExtrema {
  final UnitOfWorkProvider _uowProvider;

  GetExtrema(this._uowProvider);

  Future<LakeDataExtrema<LocalizedLakeData>?> call(Uuid lakeId) async {
    return await _uowProvider.withUnitOfWork((uow) async {
      final lake = await uow.lakeRepo.getLake(lakeId);
      if (lake == null) {
        throw LakeNotFoundException(lakeId);
      }

      final location = tz.getLocation(lake.timeZoneId);

      final result = await uow.temperatureRepo.getExtrema(lakeId);
      return result?.localize(location);
    });
  }
}
