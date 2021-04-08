import 'package:woog_api/model/lake.dart';
import 'package:woog_api/model/lake_data.dart';
import 'package:woog_api/src/memory_lake_repository.dart';

abstract class LakeRepository {
  factory LakeRepository.memoryRepo() => MemoryLakeRepository.initial();

  Future<Set<Lake>> getLakes();

  Future<Lake?> getLake(String lakeId);

  Future<void> updateData(String lakeId, LakeData data);
}

class NotFoundException implements Exception {
  final String id;
  final String message;

  const NotFoundException(this.id, this.message);

  @override
  String toString() {
    return '$message: $id';
  }
}
