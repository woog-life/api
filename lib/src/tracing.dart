import 'package:opentelemetry/api.dart';

extension OpenTelemetry on Tracer {
  T withSpan<T>({
    required String name,
    SpanKind kind = SpanKind.internal,
    List<Attribute> attributes = const [],
    required T Function() action,
  }) {
    final span = startSpan(
      name,
      kind: kind,
      attributes: attributes,
    );
    final context = Context.current.withSpan(span);
    try {
      return context.execute(action);
    } catch (e, s) {
      span
        ..setStatus(StatusCode.error, e.toString())
        ..recordException(e, stackTrace: s);
      rethrow;
    } finally {
      span.end();
    }
  }
}
