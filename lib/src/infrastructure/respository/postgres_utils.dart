import 'dart:async';

import 'package:opentelemetry/api.dart';
import 'package:postgres/postgres.dart';
import 'package:woog_api/src/tracing.dart';

final Tracer _tracer = globalTracerProvider.getTracer('postgres_utils');

extension DatabaseOpenTelemetry on Tracer {
  Future<T> withDatabaseSpan<T>({
    required String sql,
    required Future<T> Function() action,
  }) {
    final operation = sql.trimLeft().split(' ').first;
    return withSpan(
      name: operation,
      kind: SpanKind.client,
      attributes: [
        Attribute.fromString('db.name', 'woog'),
        Attribute.fromString('db.operation', operation),
        Attribute.fromString('db.statement', sql),
      ],
      action: action,
    );
  }
}

extension PreparedStatements on Session {
  Future<Result> executePrepared(
    String sql, {
    required Map<String, Object?> parameters,
  }) {
    final tracer = _tracer;
    return tracer.withDatabaseSpan(
      sql: sql,
      action: () async {
        final statement = await tracer.withSpan(
          name: 'Statement preparation',
          action: () => prepare(Sql.named(sql)),
        );
        try {
          return await statement.run(parameters);
        } finally {
          await tracer.withSpan(
            name: 'Statement disposal',
            action: statement.dispose,
          );
        }
      },
    );
  }
}
