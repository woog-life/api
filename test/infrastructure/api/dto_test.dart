import 'package:test/test.dart';
import 'package:woog_api/src/domain/model/lake_data.dart';
import 'package:woog_api/src/domain/model/region.dart';
import 'package:woog_api/src/infrastructure/api/dto.dart';

void main() {
  final time = DateTime(2022, 11, 19);
  final data = LakeData(
    time: time,
    temperature: 12.5,
  );
  group('fromData respects formatRegion', () {
    test('germany', () {
      final dto = LakeDataDto.fromData(
        data,
        precision: 1,
        formatRegion: Region.germany,
      );
      expect(dto.preciseTemperature, '12,5');
    });
  });
}
