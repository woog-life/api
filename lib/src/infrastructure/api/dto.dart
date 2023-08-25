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

  const LakeInfoDto({
    required this.id,
    required this.name,
    required this.features,
  });

  factory LakeInfoDto.fromLake(Lake lake) {
    return LakeInfoDto(
      id: lake.id.toString(),
      name: lake.name,
      features:
          lake.features.map(FeatureDto.fromFeature).toList(growable: false),
    );
  }

  factory LakeInfoDto.fromJson(Map<String, dynamic> json) =>
      _$LakeInfoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LakeInfoDtoToJson(this);
}

enum FeatureDto {
  temperature,
  booking,
  ;

  static FeatureDto fromFeature(Feature feature) {
    switch (feature) {
      case Feature.temperature:
        return FeatureDto.temperature;
      case Feature.booking:
        return FeatureDto.booking;
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
final class EventDto {
  final String variation;
  final String bookingLink;
  final DateTime beginTime;
  final DateTime endTime;
  final DateTime saleStartTime;

  const EventDto({
    required this.variation,
    required this.bookingLink,
    required this.beginTime,
    required this.endTime,
    required this.saleStartTime,
  });

  factory EventDto.fromJson(Map<String, dynamic> json) =>
      _$EventDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EventDtoToJson(this);
}

@JsonSerializable()
@immutable
final class EventsDto {
  final List<EventDto> events;

  const EventsDto(this.events);

  factory EventsDto.fromJson(Map<String, dynamic> json) =>
      _$EventsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EventsDtoToJson(this);
}

@JsonSerializable()
@immutable
final class EventUpdateDto {
  final String bookingLink;
  final DateTime beginTime;
  final DateTime endTime;
  final DateTime saleStartTime;
  final bool isAvailable;

  const EventUpdateDto({
    required this.bookingLink,
    required this.beginTime,
    required this.endTime,
    required this.saleStartTime,
    required this.isAvailable,
  });

  factory EventUpdateDto.fromJson(Map<String, dynamic> json) =>
      _$EventUpdateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EventUpdateDtoToJson(this);
}

@JsonSerializable()
@immutable
final class EventsUpdateDto {
  final String variation;
  final List<EventUpdateDto> events;

  const EventsUpdateDto({
    required this.variation,
    required this.events,
  });

  factory EventsUpdateDto.fromJson(Map<String, dynamic> json) =>
      _$EventsUpdateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EventsUpdateDtoToJson(this);
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

@JsonSerializable()
@immutable
final class LegacyEventUpdateDto implements EventUpdateDto {
  @override
  @JsonKey(name: 'booking_link')
  final String bookingLink;
  @override
  @JsonKey(name: 'begin_time')
  final DateTime beginTime;
  @override
  @JsonKey(name: 'end_time')
  final DateTime endTime;
  @override
  @JsonKey(name: 'sale_start')
  final DateTime saleStartTime;
  @override
  @JsonKey(name: 'is_available')
  final bool isAvailable;

  const LegacyEventUpdateDto({
    required this.bookingLink,
    required this.beginTime,
    required this.endTime,
    required this.saleStartTime,
    required this.isAvailable,
  });

  factory LegacyEventUpdateDto.fromJson(Map<String, dynamic> json) =>
      _$LegacyEventUpdateDtoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$LegacyEventUpdateDtoToJson(this);
}

@JsonSerializable()
@immutable
final class LegacyEventsUpdateDto implements EventsUpdateDto {
  @override
  final String variation;
  @override
  final List<LegacyEventUpdateDto> events;

  const LegacyEventsUpdateDto({
    required this.variation,
    required this.events,
  });

  factory LegacyEventsUpdateDto.fromJson(Map<String, dynamic> json) =>
      _$LegacyEventsUpdateDtoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$LegacyEventsUpdateDtoToJson(this);
}
