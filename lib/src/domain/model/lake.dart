import 'package:meta/meta.dart';

@immutable
class Lake {
  // TODO: change to UUID
  final String id;
  final String name;
  final Set<Feature> features;

  const Lake({
    required this.id,
    required this.name,
    required this.features,
  });
}

enum Feature {
  temperature,
  booking,
}
