import 'package:injectable/injectable.dart';
import 'package:woog_api/src/application/repository/temperature.dart';
import 'package:woog_api/src/domain/model/lake_data.dart';

@injectable
class GetTemperature {
  final TemperatureRepository _repo;

  GetTemperature(this._repo);

  Future<LakeData?> call(String lakeId) {
    return _repo.getLakeData(lakeId);
  }
}
