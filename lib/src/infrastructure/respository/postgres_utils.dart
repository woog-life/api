import 'package:postgres/postgres.dart';

extension PreparedStatements on Session {
  Future<Result> executePrepared(
    String sql, {
    required Map<String, Object?> parameters,
  }) async {
    final statement = await prepare(Sql.named(sql));
    try {
      return await statement.run(parameters);
    } finally {
      await statement.dispose();
    }
  }

  Future<T> streamedQuery<T>(
    String sql,
    Map<String, Object> parameters,
    Future<T> Function(ResultStream result) action,
  ) async {
    final statement = await prepare(Sql.named(sql));
    try {
      final rows = statement.bind(parameters);
      return await action(rows);
    } finally {
      await statement.dispose();
    }
  }
}
