import 'dart:io';

import 'package:woog_api/src/logger.dart';
import 'package:woog_api/src/version.dart';
import 'package:woog_api/woog_api.dart';


Future<void> main(List<String> arguments) async {
  await WoogApi().launch();
  logger.i('Started API version $packageVersion');
}
