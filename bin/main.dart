import 'package:woog_api/src/infrastructure/application.dart';
import 'package:woog_api/src/version.dart';

Future<void> main(List<String> arguments) async {
  final app = Application();
  await app.launch();
  app.logger.i('Started API version $packageVersion');
}
