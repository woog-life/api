import 'lake_data.dart';

class Lake {
  // TODO: change to UUID
  final String id;
  final String name;
  LakeData? _data;

  LakeData? get data => _data;

  Lake({
    required this.id,
    required this.name,
    LakeData? data,
  }) : _data = data;

  // ignore: use_setters_to_change_properties
  void setData(LakeData data) {
    _data = data;
  }
}

final bigWoog = Lake(
  id: '69c8438b-5aef-442f-a70d-e0d783ea2b38',
  name: 'Großer Woog',
);

final muehlchen = Lake(
  id: '25aa2968-e34e-4f86-87cc-56b16b5aff36',
  name: 'Arheilger Mühlchen',
);

final alster = Lake(
  id: '55e5f52a-2de8-458a-828f-3c043ef458d9',
  name: 'Alster in Hamburg',
);
