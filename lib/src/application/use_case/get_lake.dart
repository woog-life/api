import 'package:injectable/injectable.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/domain/model/lake.dart';

@injectable
class GetLake {
  final LakeRepository _repo;

  GetLake(this._repo);

  Future<Lake?> call(String lakeId) async {
    return _repo.getLake(lakeId);
  }
}
