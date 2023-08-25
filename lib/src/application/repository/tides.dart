import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/model/tidal_extremum_data.dart';

abstract interface class TidesRepository {
  Future<List<TidalExtremumData>> getTidalExtremaAfter({
    required Uuid lakeId,
    required DateTime time,
    required int limit,
  });

  Future<TidalExtremumData?> getLastTidalExtremum({
    required Uuid lakeId,
    required DateTime time,
  });
}
