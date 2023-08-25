import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';

import 'package:woog_api/src/application/exception/time.dart';
import 'package:woog_api/src/application/model/tidal_extremum_data.dart';

@injectable
final class GetTidalExtrema {
  GetTidalExtrema();

  Future<List<TidalExtremumData>> call({
    required Uuid lakeId,
    required DateTime? time,
    required int? upcomingLimit,
  }) async {
    if (time == null) {
      time = DateTime.now().toUtc();
    } else if (!time.isUtc) {
      throw NonUtcTimeException(time);
    }

    return [];
  }
}
