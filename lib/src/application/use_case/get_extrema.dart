import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/repository/temperature.dart';

@injectable
final class GetExtrema {
  final TemperatureRepository _repo;

  GetExtrema(this._repo);

  Future<LakeDataExtrema?> call(Uuid lakeId) {
    return _repo.getExtrema(lakeId);
  }
}
