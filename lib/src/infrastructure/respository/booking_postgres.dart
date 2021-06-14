import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:postgres/postgres.dart';
import 'package:woog_api/src/application/repository/booking.dart';
import 'package:woog_api/src/domain/model/event.dart';
import 'package:woog_api/src/infrastructure/respository/lake_postgres.dart'
    as lake;
import 'package:woog_api/src/infrastructure/respository/migrator.dart';

const tableName = 'booking';
const columnLakeId = 'lake_id';
const columnVariation = 'variation';
const columnBeginTime = 'begin_time';
const columnEndTime = 'end_time';
const columnSaleStartTime = 'sale_start_time';
const columnBookingLink = 'booking_link';
const columnAvailable = 'available';

@Injectable(as: BookingRepository)
class SqlBookingRepository implements BookingRepository {
  final Future<PostgreSQLConnection> _connection;

  SqlBookingRepository(GetIt getIt) : _connection = getIt.getAsync();

  Event _eventFromRow(Map<String, dynamic> row) {
    final variation = row[columnVariation];
    final bookingLink = row[columnBookingLink];
    final isAvailable = row[columnAvailable];
    final beginTime = row[columnBeginTime];
    final endTime = row[columnEndTime];
    final saleStartTime = row[columnSaleStartTime];

    return Event(
      variation: variation as String,
      bookingLink: bookingLink as String,
      beginTime: beginTime as DateTime,
      endTime: endTime as DateTime,
      saleStartTime: saleStartTime as DateTime,
      isAvailable: isAvailable as bool,
    );
  }

  @override
  Future<List<Event>> getAvailableEvents(
    String lakeId,
    DateTime endsAfter,
  ) async {
    final connection = await _connection;
    final result = await connection.mappedResultsQuery(
      '''
        SELECT * FROM $tableName
        WHERE $columnLakeId = @lakeId 
          AND $columnEndTime > @endTime
          AND $columnAvailable = TRUE
        ORDER BY $columnBeginTime
      ''',
      substitutionValues: {
        'lakeId': lakeId,
        'endTime': endsAfter,
      },
    );

    return result.map((e) => e[tableName]!).map(_eventFromRow).toList();
  }

  @override
  Future<void> updateEvents(
    String lakeId,
    List<Event> events,
  ) async {
    final connection = await _connection;
    for (final event in events) {
      await connection.execute(
        '''
        INSERT INTO $tableName(
          $columnLakeId,
          $columnVariation,
          $columnBookingLink,
          $columnAvailable,
          $columnBeginTime,
          $columnEndTime,
          $columnSaleStartTime
        ) VALUES (
          @lakeId,
          @variation,
          @bookingLink,
          @available,
          @beginTime,
          @endTime,
          @saleStartTime
        ) 
        ON CONFLICT ($columnLakeId, $columnVariation, $columnBeginTime)
        DO UPDATE SET $columnAvailable = @available;
        ''',
        substitutionValues: {
          'lakeId': lakeId,
          'variation': event.variation,
          'bookingLink': event.bookingLink,
          'available': event.isAvailable,
          'beginTime': event.beginTime,
          'endTime': event.endTime,
          'saleStartTime': event.saleStartTime,
        },
      );
    }
  }
}

@injectable
class SqlBookingRepositoryMigrator implements RepositoryMigrator {
  @override
  Future<void> create(PostgreSQLExecutionContext batch) async {
    await batch.execute(
      '''
      CREATE TABLE $tableName (
        $columnLakeId uuid NOT NULL 
          REFERENCES ${lake.lakeTableName}(${lake.columnLakeId}),
        $columnVariation text NOT NULL,
        $columnBeginTime timestamp NOT NULL,
        $columnEndTime timestamp NOT NULL,
        $columnSaleStartTime timestamp NOT NULL,
        $columnBookingLink text NOT NULL,
        $columnAvailable boolean NOT NULL,
        PRIMARY KEY($columnLakeId, $columnVariation, $columnBeginTime)
      );
      ''',
    );
    await batch.execute(
      '''
        CREATE INDEX idx_time ON $tableName (
          $columnLakeId,
          $columnEndTime
        );
        ''',
    );
  }

  @override
  Future<void> upgrade(
    PostgreSQLExecutionContext transaction,
    int oldVersion,
    int newVersion,
  ) async {
    if (newVersion == 3) {
      await create(transaction);
    }
  }
}
