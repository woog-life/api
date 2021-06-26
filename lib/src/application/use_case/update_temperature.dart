import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/repository/exception.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/application/repository/temperature.dart';
import 'package:woog_api/src/domain/exception/lake_not_found.dart';
import 'package:woog_api/src/domain/exception/time.dart';
import 'package:woog_api/src/domain/exception/unsupported.dart';
import 'package:woog_api/src/domain/model/lake.dart';
import 'package:woog_api/src/domain/model/lake_data.dart';

@injectable
class UpdateTemperature {
  final LakeRepository _lakeRepo;
  final TemperatureRepository _temperatureRepo;

  UpdateTemperature(this._lakeRepo, this._temperatureRepo);

  Future<void> call(Uuid lakeId, DateTime time, double temperature) async {
    final lake = await _lakeRepo.getLake(lakeId);
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
      _temperatureRepo.updateData(lakeId, data);
    } on NotFoundException {
      throw LakeNotFoundException(lakeId);
    }
  }
}
