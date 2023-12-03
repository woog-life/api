import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/exception/not_found.dart';
import 'package:woog_api/src/application/exception/time.dart';
import 'package:woog_api/src/application/exception/unsupported.dart';
import 'package:woog_api/src/application/model/lake.dart';
import 'package:woog_api/src/application/model/tidal_extremum_data.dart';
import 'package:woog_api/src/application/repository/unit_of_work.dart';

@injectable
final class UpdateTidalExtrema {
  final Logger _logger;
  final UnitOfWorkProvider _uowProvider;

  UpdateTidalExtrema(
    this._logger,
    this._uowProvider,
  );

  Future<void> call({
    required Uuid lakeId,
    required List<TidalExtremumData> data,
  }) async {
    await _uowProvider.withUnitOfWork(
      name: 'UpdateTidalExtrema',
      action: (uow) async {
        final lake = await uow.lakeRepo.getLake(lakeId);

        if (lake == null) {
          throw LakeNotFoundException(lakeId);
        } else if (!lake.features.contains(Feature.tides)) {
          throw UnsupportedFeatureException(Feature.tides);
        }

        data.sort();

        for (final extremum in data) {
          if (!extremum.time.isUtc) {
            throw NonUtcTimeException(extremum.time);
          }
        }

        // These two really should run in one transaction, but well...
        await _deleteObsoleteData(uow, lakeId, data.first, data.last);
        _logger.i('Inserting tidal data');
        await uow.tidesRepo.insertData(lakeId, data);
      },
    );
  }

  Future<void> _deleteObsoleteData(
    UnitOfWork uow,
    Uuid lakeId,
    TidalExtremumData first,
    TidalExtremumData last,
  ) async {
    _logger.i('Deleting obsolete data for lake $lakeId');
    /*
    We try to find existing data before and after the new data. If we find any,
    we make sure that there high-low tide rhythms works out, otherwise we delete
    the neighboring data points.
     */
    final left = await uow.tidesRepo.getLastTidalExtremum(
      lakeId: lakeId,
      time: first.time,
    );
    final DateTime deleteStart;
    if (left != null && left.isHighTide == first.isHighTide) {
      // Delete left data point
      deleteStart = left.time;
    } else {
      // Only delete whatever is in DB starting with first
      deleteStart = first.time;
    }

    final rights = await uow.tidesRepo.getTidalExtremaAfter(
      lakeId: lakeId,
      time: last.time,
      limit: 2,
    );
    final DateTime deleteEnd;
    if (rights.isEmpty) {
      // No data after new inserts
      deleteEnd = last.time;
    } else if (rights[0].isHighTide == last.isHighTide) {
      deleteEnd = rights[0].time;
    } else if (rights[0].time == last.time) {
      // We have to delete the conflict (highly unlikely, but still)
      if (rights.length == 2) {
        // Delete the next two entries, because the next one will be the same
        // extremum as our last insert.
        deleteEnd = rights[1].time;
      } else {
        deleteEnd = rights[0].time;
      }
    } else {
      deleteEnd = last.time;
    }

    await uow.tidesRepo.deleteBetween(
      lakeId: lakeId,
      startInclusive: deleteStart,
      endInclusive: deleteEnd,
    );
  }
}
