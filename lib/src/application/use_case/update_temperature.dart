import 'package:injectable/injectable.dart';
import 'package:woog_api/src/application/repository/exception.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/domain/error/lake_not_found.dart';
import 'package:woog_api/src/domain/error/time.dart';
import 'package:woog_api/src/domain/model/lake_data.dart';

@injectable
class UpdateTemperature {
  final LakeRepository _repo;

  UpdateTemperature(this._repo);

  Future<void> call(String lakeId, DateTime time, double temperature) async {
    if (!time.isUtc) {
      throw NonUtcTimeError(time);
    }

    if (time.isAfter(DateTime.now())) {
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
