import 'package:injectable/injectable.dart';
import 'package:woog_api/src/application/model/lake.dart';
import 'package:woog_api/src/application/repository/unit_of_work.dart';

@injectable
final class GetLakes {
  final UnitOfWorkProvider _uowProvider;

  GetLakes(this._uowProvider);

  Future<List<Lake>> call() async {
    return await _uowProvider.withUnitOfWork(
      name: 'GetLakes',
      action: (uow) async {
        final lakes = await uow.lakeRepo.getLakes();
        final result = lakes
            .where((element) => element.features.isNotEmpty)
            .toList(growable: false);

        result.sort((a, b) => a.name.compareTo(b.name));

        return result;
      },
    );
  }
}
