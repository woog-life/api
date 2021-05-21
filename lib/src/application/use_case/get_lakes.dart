import 'package:injectable/injectable.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/domain/model/lake.dart';

@injectable
class GetLakes {
  final LakeRepository _repo;

  GetLakes(this._repo);

  Future<List<Lake>> call() async {
    final lakes = await _repo.getLakes();
    return lakes.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
