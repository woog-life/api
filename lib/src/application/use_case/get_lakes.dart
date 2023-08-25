import 'package:injectable/injectable.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/domain/model/lake.dart';

@injectable
final class GetLakes {
  final LakeRepository _repo;

  GetLakes(this._repo);

  Future<List<Lake>> call() async {
    final lakes = await _repo.getLakes();
    final result = lakes
        .where((element) => element.features.isNotEmpty)
        .toList(growable: false);

    result.sort((a, b) => a.name.compareTo(b.name));

    return result;
  }
}
