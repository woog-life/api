import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/exception/not_found.dart';
import 'package:woog_api/src/application/exception/time.dart';
import 'package:woog_api/src/application/exception/unsupported.dart';
import 'package:woog_api/src/application/model/lake.dart';
import 'package:woog_api/src/application/model/lake_data.dart';
import 'package:woog_api/src/application/repository/unit_of_work.dart';

@injectable
final class UpdateTemperature {
  final UnitOfWorkProvider _uowProvider;

  UpdateTemperature(this._uowProvider);

  Future<void> call(Uuid lakeId, DateTime time, double temperature) async {
    return await _uowProvider.withUnitOfWork((uow) async {
      final lake = await uow.lakeRepo.getLake(lakeId);
      if (lake == null) {
        throw LakeNotFoundException(lakeId);
      }

      if (!lake.features.contains(Feature.temperature)) {
        throw const UnsupportedFeatureException(Feature.temperature);
      }

      if (!time.isUtc) {
        throw NonUtcTimeException(time);
      }

      final aMinuteFromNow = DateTime.now().add(const Duration(minutes: 1));
      if (time.isAfter(aMinuteFromNow)) {
        throw FutureTimeException(time);
      }

      final data = LakeData(
        time: time,
        temperature: temperature,
      );
      try {
        await uow.temperatureRepo.updateData(lakeId, data);
      } on NotFoundException {
        throw LakeNotFoundException(lakeId);
      }
    });
  }
}
