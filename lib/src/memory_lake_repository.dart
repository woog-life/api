import 'package:woog_api/lake_repository.dart';
import 'package:woog_api/model/lake.dart';
import 'package:woog_api/model/lake_data.dart';

class MemoryLakeRepository implements LakeRepository {
  final Map<String, Lake> _lakes;

  MemoryLakeRepository.initial() : _lakes = {bigWoog.id: bigWoog};

  @override
  Future<Lake?> getLake(String lakeId) {
    return Future.value(_lakes[lakeId]);
  }

  @override
  Future<Set<Lake>> getLakes() {
    return Future.value(Set.of(_lakes.values));
  }

  @override
  Future<void> updateData(String lakeId, LakeData data) async {
    final lake = _lakes[lakeId];
    if (lake == null) {
      throw NotFoundException(lakeId, 'No such lake');
    }
    lake.setData(data);
  }
}
