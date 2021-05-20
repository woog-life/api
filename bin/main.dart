import 'package:woog_api/src/infrastructure/application.dart';

Future<void> main(List<String> arguments) async {
  final app = await Application.create();
  await app.launch();
  final config = app.config;
  app.logger.i(
    'Started API version ${config.version} (${config.build})',
  );
}
