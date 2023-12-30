import 'dart:io';

import 'package:woog_api/src/application.dart';

Future<void> main(List<String> arguments) async {
  final Application app;

  try {
    app = await Application.create();
    await app.launch();
  } catch (e) {
    print('Fucked up initialization: $e');
    exit(1);
  }

  final config = app.config;
  app.logger.i(
    'Started API version ${config.version} (${config.build})',
  );
}
