class NotFoundException implements Exception {
  final String id;
  final String message;

  const NotFoundException(this.id, this.message);

  @override
  String toString() {
    return '$message: $id';
  }
}
