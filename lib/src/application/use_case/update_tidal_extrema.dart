import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/exception/unsupported.dart';
import 'package:woog_api/src/application/model/tidal_extremum_data.dart';
import 'package:woog_api/src/application/model/lake.dart';

@injectable
final class UpdateTidalExtrema {
  UpdateTidalExtrema();

  Future<void> call({
    required Uuid lakeId,
    required List<TidalExtremumData> data,
  }) async {
    throw UnsupportedFeatureException(Feature.tides);
  }
}
