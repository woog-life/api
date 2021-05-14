import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:woog_api/src/domain/model/lake_data.dart' as model;
import 'package:woog_api/src/domain/model/lake.dart';

part 'dto.g.dart';

@JsonSerializable()
@immutable
class LakeInfoDto {
  final String id;
  final String name;

  const LakeInfoDto({required this.id, required this.name});

  factory LakeInfoDto.fromLake(Lake lake) {
    return LakeInfoDto(id: lake.id, name: lake.name);
  }

  factory LakeInfoDto.fromJson(Map<String, dynamic> json) =>
      _$LakeInfoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LakeInfoDtoToJson(this);
}

@JsonSerializable()
@immutable
class LakeInfoListDto {
  final List<LakeInfoDto> lakes;

  const LakeInfoListDto(this.lakes);

  factory LakeInfoListDto.of(Iterable<Lake> lakes) {
    return LakeInfoListDto(
      lakes.map((lake) => LakeInfoDto.fromLake(lake)).toList(growable: false),
    );
  }

  factory LakeInfoListDto.fromJson(Map<String, dynamic> json) =>
      _$LakeInfoListDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LakeInfoListDtoToJson(this);
}

@JsonSerializable()
@immutable
class LakeStateDto {
  final String id;
  final String name;
  final LakeDataDto? data;

  const LakeStateDto({
    required this.id,
    required this.name,
    required this.data,
  });

  factory LakeStateDto.fromLake(Lake lake, {int? precision}) {
    final data = lake.data;
    return LakeStateDto(
      id: lake.id,
      name: lake.name,
      data: data == null
          ? null
          : LakeDataDto.fromData(data, precision: precision),
    );
  }

  factory LakeStateDto.fromJson(Map<String, dynamic> json) =>
      _$LakeStateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LakeStateDtoToJson(this);
}

@JsonSerializable()
@immutable
class LakeDataDto {
  final DateTime time;
  final int temperature;
  final String preciseTemperature;

  const LakeDataDto({
    required this.time,
    required this.temperature,
    required this.preciseTemperature,
  });

  factory LakeDataDto.fromData(model.LakeData data, {int? precision}) {
    return LakeDataDto(
      time: data.time,
      temperature: data.temperature.round(),
      preciseTemperature: data.temperature.toStringAsFixed(precision ?? 2),
    );
  }

  factory LakeDataDto.fromJson(Map<String, dynamic> json) =>
      _$LakeDataDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LakeDataDtoToJson(this);
}

@JsonSerializable()
@immutable
class TemperatureUpdateDto {
  final DateTime time;
  final double temperature;

  const TemperatureUpdateDto({required this.time, required this.temperature});

  factory TemperatureUpdateDto.fromJson(Map<String, dynamic> json) =>
      _$TemperatureUpdateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TemperatureUpdateDtoToJson(this);

  model.LakeData toData() {
    return model.LakeData(
      time: time,
      temperature: temperature,
    );
  }
}