import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/domain/model/lake.dart';

@injectable
final class GetLake {
  final LakeRepository _repo;

  GetLake(this._repo);

  Future<Lake?> call(Uuid lakeId) async {
    return _repo.getLake(lakeId);
  }
}
