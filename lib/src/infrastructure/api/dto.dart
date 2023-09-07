import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:woog_api/src/application/model/lake.dart';
import 'package:woog_api/src/application/model/lake_data.dart' as model;
import 'package:woog_api/src/application/model/region.dart';

part 'dto.g.dart';

@JsonSerializable()
@immutable
final class LakeInfoDto {
  final String id;
  final String name;
  final List<FeatureDto> features;
  final List<FeatureDto> supportedFeatures;

  const LakeInfoDto({
    required this.id,
    required this.name,
    required this.supportedFeatures,
  }) : features = supportedFeatures;

  factory LakeInfoDto.fromLake(Lake lake) {
    return LakeInfoDto(
      id: lake.id.toString(),
      name: lake.name,
      supportedFeatures:
          lake.features.map(FeatureDto.fromFeature).toList(growable: false),
    );
  }

  factory LakeInfoDto.fromJson(Map<String, dynamic> json) =>
      _$LakeInfoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LakeInfoDtoToJson(this);
}

enum FeatureDto {
  temperature,
  tides,
  ;

  static FeatureDto fromFeature(Feature feature) {
    switch (feature) {
      case Feature.temperature:
        return FeatureDto.temperature;
      case Feature.tides:
        return FeatureDto.tides;
    }
  }
}

@JsonSerializable()
@immutable
final class LakeInfoListDto {
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
final class LakeDataDto {
  final DateTime time;
  final int temperature;
  final String preciseTemperature;

  const LakeDataDto({
    required this.time,
    required this.temperature,
    required this.preciseTemperature,
  });

  factory LakeDataDto.fromData(
    model.LakeData data, {
    int? precision,
    required Region formatRegion,
  }) {
    var preciseTemperature = data.temperature.toStringAsFixed(precision ?? 2);
    preciseTemperature = preciseTemperature.replaceAll(
      '.',
      formatRegion.decimalSeparator,
    );
    return LakeDataDto(
      time: data.time,
      temperature: data.temperature.round(),
      preciseTemperature: preciseTemperature,
    );
  }

  factory LakeDataDto.fromJson(Map<String, dynamic> json) =>
      _$LakeDataDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LakeDataDtoToJson(this);
}

@JsonSerializable()
@immutable
final class LakeDataExtremaDto {
  final LakeDataDto min;
  final LakeDataDto max;

  const LakeDataExtremaDto({
    required this.min,
    required this.max,
  });

  factory LakeDataExtremaDto.fromData(
    model.LakeData min,
    model.LakeData max, {
    int? precision,
    required Region formatRegion,
  }) {
    return LakeDataExtremaDto(
      min: LakeDataDto.fromData(
        min,
        precision: precision,
        formatRegion: formatRegion,
      ),
      max: LakeDataDto.fromData(
        max,
        precision: precision,
        formatRegion: formatRegion,
      ),
    );
  }

  factory LakeDataExtremaDto.fromJson(Map<String, dynamic> json) =>
      _$LakeDataExtremaDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LakeDataExtremaDtoToJson(this);
}

@JsonSerializable()
@immutable
final class TemperatureUpdateDto {
  final DateTime time;
  final double temperature;

  const TemperatureUpdateDto({required this.time, required this.temperature});

  factory TemperatureUpdateDto.fromJson(Map<String, dynamic> json) =>
      _$TemperatureUpdateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TemperatureUpdateDtoToJson(this);
}

@JsonSerializable()
@immutable
final class TidalExtremaDto {
  final List<TidalExtremumDataDto> extrema;

  const TidalExtremaDto({required this.extrema});

  factory TidalExtremaDto.fromJson(Map<String, dynamic> json) =>
      _$TidalExtremaDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TidalExtremaDtoToJson(this);
}

@JsonSerializable()
@immutable
final class TidalExtremumDataDto {
  final bool isHighTide;
  final DateTime time;
  final String height;

  const TidalExtremumDataDto({
    required this.isHighTide,
    required this.time,
    required this.height,
  });

  factory TidalExtremumDataDto.fromJson(Map<String, dynamic> json) =>
      _$TidalExtremumDataDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TidalExtremumDataDtoToJson(this);
}

@JsonSerializable()
@immutable
final class ErrorMessageDto {
  final String errorMessage;

  const ErrorMessageDto(this.errorMessage);

  factory ErrorMessageDto.fromJson(Map<String, dynamic> json) =>
      _$ErrorMessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorMessageDtoToJson(this);
}
