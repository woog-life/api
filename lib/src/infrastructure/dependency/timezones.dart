import 'package:injectable/injectable.dart';
import 'package:woog_api/src/config.dart';
import 'package:timezone/data/latest.dart' as tz;

class TimeZoneModuleStub {}

@module
abstract class TimezoneModule {
  @preResolve
  @singleton
  Future<TimeZoneModuleStub> initializeTimezones(
    Config config,
  ) async {
    tz.initializeTimeZones();
    return TimeZoneModuleStub();
  }
}
