class LakeNotFoundError implements Exception {
  final String lakeId;

  LakeNotFoundError(this.lakeId);

  @override
  String toString() {
    return 'Lake not found: $lakeId';
  }
}
