import 'dart:io';

import 'package:injectable/injectable.dart';

@singleton
@injectable
class Config {
  final String apiKey;
  final String databasePath;
  final String sentryDsn;

  factory Config() {
    final environment = Platform.environment;
    return Config._(
      apiKey: _Variable(
        name: 'API_KEY',
        defaultValue: 'default-api-key',
      ).resolve(environment),
      databasePath: _Variable(
        name: 'DATABASE_PATH',
        defaultValue: 'woog.db',
      ).resolve(environment),
      sentryDsn: _Variable(
        name: 'SENTRY_DSN',
        defaultValue: '',
      ).resolve(environment),
    );
  }

  Config._({
    required this.apiKey,
    required this.databasePath,
    required this.sentryDsn,
  });
}

class _Variable {
  final String name;
  final String defaultValue;

  _Variable({
    required this.name,
    required this.defaultValue,
  });

  String resolve(Map<String, String> environment) {
    final value = environment[name];
    if (value == null) {
      stderr.writeln('$name environment variable not set');
      return defaultValue;
    } else if (value.isEmpty) {
      throw StateError('Empty $name set');
    } else {
      return value;
    }
  }
}
