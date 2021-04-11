import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:woog_api/model/lake.dart';
import 'package:woog_api/model/lake_data.dart' as model;

part 'dto.g.dart';

@JsonSerializable()
@immutable
class LakeInfo {
  final String id;
  final String name;

  const LakeInfo({required this.id, required this.name});

  factory LakeInfo.fromLake(Lake lake) {
    return LakeInfo(id: lake.id, name: lake.name);
  }

  factory LakeInfo.fromJson(Map<String, dynamic> json) =>
      _$LakeInfoFromJson(json);

  Map<String, dynamic> toJson() => _$LakeInfoToJson(this);
}

@JsonSerializable()
@immutable
class LakeInfoList {
  final List<LakeInfo> lakes;

  const LakeInfoList(this.lakes);

  factory LakeInfoList.of(Iterable<Lake> lakes) {
    return LakeInfoList(
      lakes.map((lake) => LakeInfo.fromLake(lake)).toList(growable: false),
    );
  }

  factory LakeInfoList.fromJson(Map<String, dynamic> json) =>
      _$LakeInfoListFromJson(json);

  Map<String, dynamic> toJson() => _$LakeInfoListToJson(this);
}

@JsonSerializable()
@immutable
class LakeState {
  final String id;
  final String name;
  final LakeData? data;

  const LakeState({
    required this.id,
    required this.name,
    required this.data,
  });

  factory LakeState.fromLake(Lake lake, {int? precision}) {
    final data = lake.data;
    return LakeState(
      id: lake.id,
      name: lake.name,
      data: data == null ? null : LakeData.fromData(data, precision: precision),
    );
  }

  factory LakeState.fromJson(Map<String, dynamic> json) =>
      _$LakeStateFromJson(json);

  Map<String, dynamic> toJson() => _$LakeStateToJson(this);
}

@JsonSerializable()
@immutable
class LakeData {
  final DateTime time;
  final int temperature;
  final String preciseTemperature;

  const LakeData({
    required this.time,
    required this.temperature,
    required this.preciseTemperature,
  });

  factory LakeData.fromData(model.LakeData data, {int? precision}) {
    return LakeData(
      time: data.time,
      temperature: data.temperature.round(),
      preciseTemperature: data.temperature.toStringAsFixed(precision ?? 2),
    );
  }

  factory LakeData.fromJson(Map<String, dynamic> json) =>
      _$LakeDataFromJson(json);

  Map<String, dynamic> toJson() => _$LakeDataToJson(this);
}

@JsonSerializable()
@immutable
class TemperatureUpdate {
  final DateTime time;
  final double temperature;

  const TemperatureUpdate({required this.time, required this.temperature});

  factory TemperatureUpdate.fromJson(Map<String, dynamic> json) =>
      _$TemperatureUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$TemperatureUpdateToJson(this);

  model.LakeData toData() {
    return model.LakeData(
      time: time,
      temperature: temperature,
    );
  }
}
