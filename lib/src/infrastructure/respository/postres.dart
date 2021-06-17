import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:postgres/postgres.dart';

extension ConnectionUsage on GetIt {
  Future<T> useConnection<T>(
    FutureOr<T> Function(PostgreSQLConnection) block,
  ) async {
    final connection = await getAsync<PostgreSQLConnection>();
    try {
      return await block(connection);
    } finally {
      connection.close();
    }
  }
}
