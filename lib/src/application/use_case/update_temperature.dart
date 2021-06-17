import 'package:injectable/injectable.dart';
import 'package:woog_api/src/application/repository/exception.dart';
import 'package:woog_api/src/application/repository/temperature.dart';
import 'package:woog_api/src/domain/error/lake_not_found.dart';
import 'package:woog_api/src/domain/error/time.dart';
import 'package:woog_api/src/domain/model/lake_data.dart';

@injectable
class UpdateTemperature {
  final TemperatureRepository _repo;

  UpdateTemperature(this._repo);

  Future<void> call(String lakeId, DateTime time, double temperature) async {
    if (!time.isUtc) {
      throw NonUtcTimeError(time);
    }

    final aMinuteFromNow = DateTime.now().add(const Duration(minutes: 1));
    if (time.isAfter(aMinuteFromNow)) {
      throw FutureTimeError(time);
    }

    final data = LakeData(
      time: time,
      temperature: temperature,
    );
    try {
      _repo.updateData(lakeId, data);
    } on NotFoundException {
      throw LakeNotFoundError(lakeId);
    }
  }
}
