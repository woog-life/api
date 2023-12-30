import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:woog_api/src/application/model/lake.dart';
import 'package:woog_api/src/application/model/lake_data.dart' as model;
import 'package:woog_api/src/application/model/region.dart';
import 'package:woog_api/src/application/model/tidal_extremum_data.dart';

part 'dto.g.dart';

@JsonSerializable(createFactory: false)
@immutable
final class LakeInfoDto {
  final String id;
  final String name;
  final List<FeatureDto> supportedFeatures;
  final String timeZoneId;

  const LakeInfoDto({
    required this.id,
    required this.name,
    required this.supportedFeatures,
    required this.timeZoneId,
  });

  factory LakeInfoDto.fromLake(Lake lake) {
    final featureDtos =
        lake.features.map(FeatureDto.fromFeature).toList(growable: false);
    return LakeInfoDto(
      id: lake.id.toString(),
      name: lake.name,
      supportedFeatures: featureDtos,
      timeZoneId: lake.timeZoneId,
    );
  }

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

@JsonSerializable(createFactory: false)
@immutable
final class LakeInfoListDto {
  final List<LakeInfoDto> lakes;

  const LakeInfoListDto(this.lakes);

  factory LakeInfoListDto.of(Iterable<Lake> lakes) {
    return LakeInfoListDto(
      lakes.map((lake) => LakeInfoDto.fromLake(lake)).toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => _$LakeInfoListDtoToJson(this);
}

@JsonSerializable(createFactory: false)
@immutable
final class LakeDataDto {
  final DateTime time;
  final DateTime localTime;
  final int temperature;
  final String preciseTemperature;

  const LakeDataDto({
    required this.time,
    required this.localTime,
    required this.temperature,
    required this.preciseTemperature,
  });

  factory LakeDataDto.fromData(
    model.LocalizedLakeData data, {
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
      localTime: data.localTime,
      temperature: data.temperature.round(),
      preciseTemperature: preciseTemperature,
    );
  }

  Map<String, dynamic> toJson() => _$LakeDataDtoToJson(this);
}

@JsonSerializable(createFactory: false)
@immutable
final class LakeDataExtremaDto {
  final LakeDataDto min;
  final LakeDataDto max;

  const LakeDataExtremaDto({
    required this.min,
    required this.max,
  });

  factory LakeDataExtremaDto.fromData(
    model.LocalizedLakeData min,
    model.LocalizedLakeData max, {
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

  Map<String, dynamic> toJson() => _$LakeDataExtremaDtoToJson(this);
}

@JsonSerializable(createToJson: false)
@immutable
final class TemperatureUpdateDto {
  final DateTime time;
  final double temperature;

  const TemperatureUpdateDto({required this.time, required this.temperature});

  factory TemperatureUpdateDto.fromJson(Map<String, dynamic> json) =>
      _$TemperatureUpdateDtoFromJson(json);
}

@JsonSerializable(createToJson: false)
@immutable
final class TidalExtremaInputDto {
  final List<TidalExtremumInputDataDto> extrema;

  const TidalExtremaInputDto({required this.extrema});

  factory TidalExtremaInputDto.fromJson(Map<String, dynamic> json) =>
      _$TidalExtremaInputDtoFromJson(json);
}

@JsonSerializable(createToJson: false)
@immutable
final class TidalExtremumInputDataDto {
  final bool isHighTide;
  final DateTime time;
  final String height;

  const TidalExtremumInputDataDto({
    required this.isHighTide,
    required this.time,
    required this.height,
  });

  factory TidalExtremumInputDataDto.fromJson(Map<String, dynamic> json) =>
      _$TidalExtremumInputDataDtoFromJson(json);
}

@JsonSerializable(createFactory: false)
@immutable
final class TidalExtremaDto {
  final List<TidalExtremumDataDto> extrema;

  const TidalExtremaDto({required this.extrema});

  Map<String, dynamic> toJson() => _$TidalExtremaDtoToJson(this);
}

@JsonSerializable(createFactory: false)
@immutable
final class TidalExtremumDataDto {
  final bool isHighTide;
  final DateTime time;
  final DateTime localTime;
  final String height;

  const TidalExtremumDataDto({
    required this.isHighTide,
    required this.time,
    required this.localTime,
    required this.height,
  });

  factory TidalExtremumDataDto.fromData(LocalizedTidalExtremumData data) {
    return TidalExtremumDataDto(
      isHighTide: data.isHighTide,
      time: data.time,
      localTime: data.localTime,
      height: data.height,
    );
  }

  Map<String, dynamic> toJson() => _$TidalExtremumDataDtoToJson(this);
}

@JsonSerializable(createFactory: false)
@immutable
final class ErrorMessageDto {
  final String errorMessage;

  const ErrorMessageDto(this.errorMessage);

  Map<String, dynamic> toJson() => _$ErrorMessageDtoToJson(this);
}
