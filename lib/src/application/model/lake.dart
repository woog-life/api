import 'package:meta/meta.dart';
import 'package:sane_uuid/uuid.dart';

@immutable
final class Lake {
  final Uuid id;
  final String name;
  final Set<Feature> features;
  final String timeZoneId;

  const Lake({
    required this.id,
    required this.name,
    required this.features,
    required this.timeZoneId,
  });
}

enum Feature {
  temperature,
  tides,
}
