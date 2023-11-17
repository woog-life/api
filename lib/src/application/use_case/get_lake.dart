import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/model/lake.dart';
import 'package:woog_api/src/application/repository/unit_of_work.dart';

@injectable
final class GetLake {
  final UnitOfWorkProvider _uowProvider;

  GetLake(this._uowProvider);

  Future<Lake?> call(Uuid lakeId) async {
    return await _uowProvider.withUnitOfWork((uow) async {
      return uow.lakeRepo.getLake(lakeId);
    });
  }
}
