import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class Config {
  final String apiKey;
  final String databasePath;

  factory Config(Logger logger) {
    final environment = Platform.environment;
    return Config._(
      apiKey: _Variable(
        name: 'API_KEY',
        defaultValue: 'default-api-key',
      ).resolve(logger, environment),
      databasePath: _Variable(
        name: 'DATABASE_PATH',
        defaultValue: 'woog.db',
      ).resolve(logger, environment),
    );
  }

  Config._({
    required this.apiKey,
    required this.databasePath,
  });
}

class _Variable {
  final String name;
  final String defaultValue;

  _Variable({
    required this.name,
    required this.defaultValue,
  });

  String resolve(Logger logger, Map<String, String> environment) {
    final value = environment[name];
    if (value == null) {
      logger.w('$name environment variable not set');
      return defaultValue;
    } else if (value.isEmpty) {
      throw StateError('Empty $name set');
    } else {
      return value;
    }
  }
}
